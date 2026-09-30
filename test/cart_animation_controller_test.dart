import 'dart:async';

import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_controller.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_source.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/packaging_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _photoKey = ValueKey<String>('selected-product-photo');
const _flightKey = ValueKey<String>('wrap-to-cart-flight');
const _fadeKey = ValueKey<String>('cart-add-fade');

void main() {
  testWidgets('preset moves one photo continuously from its exact source', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    final bounds = tester.getRect(find.byKey(_photoKey));
    await controller.add(
      context: scene.context,
      source: scene.source,
      packagingKind: CartPackagingKind.burger,
      operation: () {},
      destination: scene.destination,
      onConfirmed: () {},
      onFailed: (_, _) => fail('Unexpected failure.'),
    );
    await _insertEffect(tester);
    expect(_overlayPhoto(), findsOneWidget);
    final initial = tester.getRect(_overlayPhoto());
    expect(initial.left, closeTo(bounds.left, .01));
    expect(initial.top, closeTo(bounds.top, .01));
    expect(initial.width, closeTo(bounds.width, .01));
    expect(initial.height, closeTo(bounds.height, .01));

    await tester.pump(const Duration(milliseconds: 200));
    expect(_overlayPhoto(), findsOneWidget);
    final moving = tester.getRect(_overlayPhoto());
    expect(moving.center, isNot(initial.center));
    expect(
      moving.width / moving.height,
      closeTo(bounds.width / bounds.height, .01),
    );
    expect(tester.getRect(find.byKey(scene.anchorKey)), bounds);
    await tester.pumpAndSettle();
    expect(find.byKey(_photoKey), findsOneWidget);
    expect(_sourceOpacity(tester, scene), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rapid additions mutate immediately and share one visual effect',
    (tester) async {
      final scene = await _mount(tester);
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      var quantity = 0;
      var confirmations = 0;
      final additions = <Future<bool>>[];

      for (var index = 0; index < 4; index++) {
        additions.add(
          controller.add(
            context: scene.context,
            source: scene.source,
            operation: () => quantity++,
            destination: scene.destination,
            onConfirmed: () => confirmations++,
            onFailed: (_, _) => fail('A successful addition must not fail.'),
          ),
        );
        expect(quantity, index + 1);
      }

      expect(await Future.wait(additions), everyElement(isTrue));
      await _insertEffect(tester);
      expect(find.byKey(_flightKey), findsOneWidget);
      expect(controller.isAnimating, isTrue);
      expect(confirmations, 3);

      // Pointer-transparent decoration must leave shopping controls usable.
      await tester.tap(find.byKey(const ValueKey('unrelated-control')));
      expect(scene.otherTaps, 1);

      await tester.pump(controller.duration + const Duration(milliseconds: 20));
      await tester.pump();
      expect(quantity, 4);
      expect(confirmations, 4);
      expect(find.byKey(_flightKey), findsNothing);
      expect(controller.isAnimating, isFalse);
      expect(_sourceOpacity(tester, scene), 1);
    },
  );

  testWidgets(
    'overlay starts at the exact source bounds and restores its photo',
    (tester) async {
      final scene = await _mount(tester);
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      final originalBounds = tester.getRect(find.byKey(_photoKey));
      var confirmations = 0;

      await controller.add(
        context: scene.context,
        source: scene.source,
        operation: () {},
        destination: scene.destination,
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
      );
      await _insertEffect(tester);

      expect(tester.getRect(_overlayPhoto()), originalBounds);
      expect(_sourceOpacity(tester, scene), 0);
      expect(tester.getRect(find.byKey(scene.anchorKey)), originalBounds);

      await tester.pump(controller.duration * (350 / 1100));
      expect(
        tester.getCenter(_overlayPhoto()).dy,
        lessThan(originalBounds.center.dy),
      );
      expect(tester.getRect(find.byKey(scene.anchorKey)), originalBounds);

      await tester.pumpAndSettle();
      expect(confirmations, 1);
      expect(_sourceOpacity(tester, scene), 1);
      expect(find.byKey(_photoKey), findsOneWidget);
      expect(tester.getRect(find.byKey(_photoKey)), originalBounds);
    },
  );

  testWidgets(
    'flight measures the moved cart at launch and enters its center',
    (tester) async {
      final scene = await _mount(tester);
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      var targetReads = 0;
      var confirmations = 0;

      await controller.add(
        context: scene.context,
        source: scene.source,
        operation: () {},
        destination: () {
          targetReads++;
          return scene.destination();
        },
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
      );
      await _insertEffect(tester);
      expect(targetReads, 1);

      await tester.pump(controller.duration * (600 / 1100));
      scene.moveCart(const Offset(420, 390));
      await tester.pump();
      final movedCart = scene.destination()!;
      expect(targetReads, 1);

      // Sample just beyond the boundary to allow floating-point tick rounding.
      await tester.pump(
        controller.duration * (50 / 1100) + const Duration(milliseconds: 1),
      );
      expect(targetReads, 2);
      await tester.pump(controller.duration * (350 / 1100));
      final arrival = tester.getCenter(_overlayPhoto());
      expect(arrival.dx, closeTo(movedCart.center.dx, 0.01));
      expect(arrival.dy, closeTo(movedCart.center.dy, 0.01));
      expect(confirmations, 1);
      expect(targetReads, 2, reason: 'The frame path must not query layout.');

      await tester.pumpAndSettle();
      expect(confirmations, 1);
    },
  );

  testWidgets('skipping directly past completion confirms exactly once', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    var confirmations = 0;

    await controller.add(
      context: scene.context,
      source: scene.source,
      operation: () {},
      destination: scene.destination,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => fail('Unexpected failure.'),
    );
    await _insertEffect(tester);
    await tester.pump(controller.duration + const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(confirmations, 1);
    expect(controller.isAnimating, isFalse);
    expect(_sourceOpacity(tester, scene), 1);
    expect(find.byKey(_flightKey), findsNothing);
  });

  testWidgets(
    'server rejection reports the failure and never confirms success',
    (tester) async {
      final scene = await _mount(tester);
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      final server = Completer<void>();
      final rejection = StateError('Cart service unavailable');
      final failures = <Object>[];
      var operations = 0;
      var confirmations = 0;
      var cancellations = 0;

      final addition = controller.add(
        context: scene.context,
        source: scene.source,
        operation: () {
          operations++;
          return server.future;
        },
        destination: scene.destination,
        onConfirmed: () => confirmations++,
        onFailed: (error, _) => failures.add(error),
        onCancelled: () => cancellations++,
      );
      expect(operations, 1);
      await tester.pump(const Duration(milliseconds: 500));
      expect(confirmations, 0);
      expect(find.byKey(_flightKey), findsNothing);

      server.completeError(rejection);
      expect(await addition, isFalse);
      await tester.pumpAndSettle();

      expect(failures, [rejection]);
      expect(confirmations, 0);
      expect(cancellations, 1);
      expect(controller.isAnimating, isFalse);
      expect(_sourceOpacity(tester, scene), 1);
    },
  );

  testWidgets('a rejected overlapping request preserves the accepted flight', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    var confirmations = 0;
    var failures = 0;

    await controller.add(
      context: scene.context,
      source: scene.source,
      operation: () {},
      destination: scene.destination,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => failures++,
    );
    await _insertEffect(tester);

    final rejected = await controller.add(
      context: scene.context,
      source: scene.source,
      operation: () => throw StateError('Second request rejected'),
      destination: scene.destination,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => failures++,
    );
    expect(rejected, isFalse);
    expect(failures, 1);
    expect(find.byKey(_flightKey), findsOneWidget);

    await tester.pumpAndSettle();
    expect(confirmations, 1);
    expect(_sourceOpacity(tester, scene), 1);
  });

  testWidgets('cancel restores the photo and permits a later fresh addition', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    var confirmations = 0;
    var cancellations = 0;

    Future<bool> add() => controller.add(
      context: scene.context,
      source: scene.source,
      operation: () {},
      destination: scene.destination,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => fail('Unexpected failure.'),
      onCancelled: () => cancellations++,
    );

    await add();
    await _insertEffect(tester);
    await tester.pump(controller.duration * (450 / 1100));
    controller.cancel();
    await tester.pumpAndSettle();
    expect(cancellations, 1);
    expect(confirmations, 0);
    expect(find.byKey(_flightKey), findsNothing);
    expect(_sourceOpacity(tester, scene), 1);

    await add();
    await _insertEffect(tester);
    expect(find.byKey(_flightKey), findsOneWidget);
    await tester.pumpAndSettle();
    expect(confirmations, 1);
    expect(cancellations, 1);
  });

  for (final dispose in [false, true]) {
    for (final reject in [false, true]) {
      testWidgets(
        '${dispose ? 'dispose' : 'cancel'} suppresses a pending server '
        '${reject ? 'rejection' : 'success'}',
        (tester) async {
          final scene = await _mount(tester);
          final controller = CartAnimationController();
          addTearDown(controller.dispose);
          final server = Completer<void>();
          var confirmations = 0;
          var failures = 0;
          var cancellations = 0;

          final addition = controller.add(
            context: scene.context,
            source: scene.source,
            operation: () => server.future,
            destination: scene.destination,
            onConfirmed: () => confirmations++,
            onFailed: (_, _) => failures++,
            onCancelled: () => cancellations++,
          );
          if (dispose) {
            controller.dispose();
          } else {
            controller.cancel();
          }
          if (reject) {
            server.completeError(StateError('Late rejection'));
          } else {
            server.complete();
          }
          expect(await addition, !reject);
          await tester.pumpAndSettle();

          expect(confirmations, 0);
          expect(failures, 0);
          expect(cancellations, 1);
          expect(controller.isAnimating, isFalse);
          expect(find.byKey(_flightKey), findsNothing);
          expect(_sourceOpacity(tester, scene), 1);
        },
      );
    }
  }

  testWidgets(
    'dispose removes an active overlay and suppresses its completion',
    (tester) async {
      final scene = await _mount(tester);
      final controller = CartAnimationController();
      var confirmations = 0;

      await controller.add(
        context: scene.context,
        source: scene.source,
        operation: () {},
        destination: scene.destination,
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
      );
      await _insertEffect(tester);
      controller.dispose();
      await tester.pumpAndSettle();

      expect(confirmations, 0);
      expect(find.byKey(_flightKey), findsNothing);
      expect(_sourceOpacity(tester, scene), 1);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion fades in place and restores the source promptly',
    (tester) async {
      final scene = await _mount(tester, reducedMotion: true);
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      final sourceBounds = scene.source.bounds;
      var confirmations = 0;
      var targetReads = 0;

      await controller.add(
        context: scene.context,
        source: scene.source,
        operation: () {},
        destination: () {
          targetReads++;
          return scene.destination();
        },
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
      );
      await _insertEffect(tester);
      expect(find.byKey(_flightKey), findsNothing);
      expect(find.byKey(_fadeKey), findsOneWidget);
      expect(_sourceOpacity(tester, scene), 1);

      await tester.pump(const Duration(milliseconds: 70));
      expect(tester.getRect(_overlayPhoto(reduced: true)), sourceBounds);
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byKey(_fadeKey),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, closeTo(0.5, 0.01));
      expect(confirmations, 1);
      expect(targetReads, 1);

      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      expect(find.byKey(_fadeKey), findsNothing);
      expect(_sourceOpacity(tester, scene), 1);
      expect(confirmations, 1);
      expect(controller.isAnimating, isFalse);
    },
  );

  testWidgets('a missing cart target confirms without hiding the product', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    var confirmations = 0;
    var operations = 0;

    await controller.add(
      context: scene.context,
      source: scene.source,
      operation: () => operations++,
      destination: () => null,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => fail('Unexpected failure.'),
    );
    await tester.pumpAndSettle();

    expect(operations, 1);
    expect(confirmations, 1);
    expect(controller.isAnimating, isFalse);
    expect(find.byKey(_flightKey), findsNothing);
    expect(_sourceOpacity(tester, scene), 1);
  });

  testWidgets('cancel before the next frame prevents a queued overlay', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    var confirmations = 0;
    var cancellations = 0;

    await controller.add(
      context: scene.context,
      source: scene.source,
      operation: () {},
      destination: scene.destination,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => fail('Unexpected failure.'),
      onCancelled: () => cancellations++,
    );
    controller.cancel();
    await tester.pumpAndSettle();

    expect(confirmations, 0);
    expect(cancellations, 1);
    expect(controller.isAnimating, isFalse);
    expect(find.byKey(_flightKey), findsNothing);
    expect(_sourceOpacity(tester, scene), 1);
  });

  testWidgets(
    'an offscreen source confirms without appearing over the screen',
    (tester) async {
      final scene = await _mount(tester);
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      final captured = scene.source;
      var confirmations = 0;

      await controller.add(
        context: scene.context,
        source: CartAnimationSource(
          bounds: captured.bounds.shift(const Offset(-200, 0)),
          child: captured.child,
          setHidden: captured.setHidden,
        ),
        operation: () {},
        destination: scene.destination,
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
      );
      await tester.pumpAndSettle();

      expect(confirmations, 1);
      expect(controller.isAnimating, isFalse);
      expect(find.byKey(_flightKey), findsNothing);
      expect(_sourceOpacity(tester, scene), 1);
    },
  );

  testWidgets('an old rejected request cannot cancel a fresh flight', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    final oldRequest = Completer<void>();
    var confirmations = 0;
    var failures = 0;

    final staleAddition = controller.add(
      context: scene.context,
      source: scene.source,
      operation: () => oldRequest.future,
      destination: scene.destination,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => failures++,
    );
    controller.cancel();
    await controller.add(
      context: scene.context,
      source: scene.source,
      operation: () {},
      destination: scene.destination,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => failures++,
    );
    await _insertEffect(tester);

    oldRequest.completeError(StateError('Old rejected request'));
    expect(await staleAddition, isFalse);
    await tester.pump();
    expect(find.byKey(_flightKey), findsOneWidget);
    expect(failures, 0);
    expect(confirmations, 0);

    await tester.pumpAndSettle();
    expect(confirmations, 1);
    expect(failures, 0);
    expect(_sourceOpacity(tester, scene), 1);
  });

  testWidgets('a cart target removed during preparation cancels cleanly', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    var targetAvailable = true;
    var confirmations = 0;
    var cancellations = 0;

    await controller.add(
      context: scene.context,
      source: scene.source,
      operation: () {},
      destination: () => targetAvailable ? scene.destination() : null,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => fail('Unexpected failure.'),
      onCancelled: () => cancellations++,
    );
    await _insertEffect(tester);
    targetAvailable = false;
    await tester.pump(
      controller.duration * (650 / 1100) + const Duration(milliseconds: 1),
    );
    await tester.pumpAndSettle();

    expect(confirmations, 0);
    expect(cancellations, 1);
    expect(find.byKey(_flightKey), findsNothing);
    expect(_sourceOpacity(tester, scene), 1);
  });

  testWidgets('a delayed accepted add starts at the photo’s current bounds', (
    tester,
  ) async {
    final scene = await _mount(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    final server = Completer<void>();
    final initialSource = scene.source;
    var confirmations = 0;

    final addition = controller.add(
      context: scene.context,
      source: initialSource,
      operation: () => server.future,
      destination: scene.destination,
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => fail('Unexpected failure.'),
    );
    scene.movePhoto(const Offset(180, 160));
    await tester.pump();
    final currentBounds = tester.getRect(find.byKey(_photoKey));
    expect(currentBounds, isNot(initialSource.bounds));

    server.complete();
    expect(await addition, isTrue);
    await _insertEffect(tester);

    expect(tester.getRect(_overlayPhoto()), currentBounds);
    expect(_sourceOpacity(tester, scene), 0);
    await tester.pumpAndSettle();
    expect(confirmations, 1);
    expect(_sourceOpacity(tester, scene), 1);
    expect(tester.getRect(find.byKey(_photoKey)), currentBounds);
  });

  testWidgets('partially clipped and disposed anchors cannot be captured', (
    tester,
  ) async {
    final anchorKey = GlobalKey<CartAnimationAnchorState>();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 160,
              child: ListView(
                controller: scroll,
                children: [
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 96,
                      height: 80,
                      child: CartAnimationAnchor(
                        key: anchorKey,
                        child: const ColoredBox(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final anchor = anchorKey.currentState!;
    expect(anchor.capture(), isNotNull);

    scroll.jumpTo(60);
    await tester.pump();
    // The photo is still inside the overall screen, but clipped by its list.
    expect(tester.getRect(find.byKey(anchorKey)).top, greaterThan(0));
    expect(anchor.capture(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(anchor.capture(), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pushing another route cancels an active flight and restores source',
    (tester) async {
      final scene = await _mount(tester);
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      var confirmations = 0;
      var cancellations = 0;
      await controller.add(
        context: scene.context,
        source: scene.source,
        operation: () {},
        destination: scene.destination,
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
        onCancelled: () => cancellations++,
      );
      await _insertEffect(tester);
      await tester.pump(controller.duration * (300 / 1100));

      unawaited(
        Navigator.of(scene.context).push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Another screen')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(confirmations, 0);
      expect(cancellations, 1);
      expect(controller.isAnimating, isFalse);
      expect(find.byKey(_flightKey), findsNothing);
      expect(_sourceOpacity(tester, scene), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'popping the source route cancels before its anchor is disposed',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final sceneKey = GlobalKey<_CartSceneState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Previous screen')),
        ),
      );
      unawaited(
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute(builder: (_) => _CartScene(key: sceneKey)),
        ),
      );
      await tester.pumpAndSettle();
      final scene = sceneKey.currentState!;
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      var confirmations = 0;
      var cancellations = 0;
      await controller.add(
        context: scene.context,
        source: scene.source,
        operation: () {},
        destination: scene.destination,
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
        onCancelled: () => cancellations++,
      );
      await _insertEffect(tester);
      await tester.pump(controller.duration * (300 / 1100));

      navigatorKey.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(_sourceOpacity(tester, scene), 1);
      await tester.pumpAndSettle();

      expect(confirmations, 0);
      expect(cancellations, 1);
      expect(controller.isAnimating, isFalse);
      expect(find.byKey(_flightKey), findsNothing);
      expect(scene.mounted, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a late server success cannot insert an effect on a covered route',
    (tester) async {
      final scene = await _mount(tester);
      final controller = CartAnimationController();
      addTearDown(controller.dispose);
      final server = Completer<void>();
      var confirmations = 0;
      var cancellations = 0;
      final addition = controller.add(
        context: scene.context,
        source: scene.source,
        operation: () => server.future,
        destination: scene.destination,
        onConfirmed: () => confirmations++,
        onFailed: (_, _) => fail('Unexpected failure.'),
        onCancelled: () => cancellations++,
      );
      unawaited(
        Navigator.of(scene.context).push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Another screen')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      server.complete();
      expect(await addition, isTrue);
      await tester.pumpAndSettle();

      expect(confirmations, 0);
      expect(cancellations, 1);
      expect(controller.isAnimating, isFalse);
      expect(find.byKey(_flightKey), findsNothing);
      expect(_sourceOpacity(tester, scene), 1);
    },
  );
}

Future<_CartSceneState> _mount(
  WidgetTester tester, {
  bool reducedMotion = false,
}) async {
  final key = GlobalKey<_CartSceneState>();
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          disableAnimations: reducedMotion,
        ),
        child: _CartScene(key: key),
      ),
    ),
  );
  return key.currentState!;
}

Future<void> _insertEffect(WidgetTester tester) async {
  // First frame measures the settled layout; the second mounts the overlay.
  await tester.pump();
  await tester.pump();
}

Finder _overlayPhoto({bool reduced = false}) => find.descendant(
  of: find.byKey(reduced ? _fadeKey : _flightKey),
  matching: find.byKey(_photoKey),
);

double _sourceOpacity(WidgetTester tester, _CartSceneState scene) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byKey(scene.anchorKey, skipOffstage: false),
        matching: find.byType(Opacity, skipOffstage: false),
        skipOffstage: false,
      ),
    )
    .opacity;

class _CartScene extends StatefulWidget {
  const _CartScene({super.key});

  @override
  State<_CartScene> createState() => _CartSceneState();
}

class _CartSceneState extends State<_CartScene> {
  final anchorKey = GlobalKey<CartAnimationAnchorState>();
  final cartKey = GlobalKey();
  Offset cartPosition = const Offset(650, 450);
  Offset photoPosition = const Offset(40, 60);
  int otherTaps = 0;

  CartAnimationSource get source => anchorKey.currentState!.capture()!;

  Rect? destination() => cartAnimationBounds(cartKey);

  void moveCart(Offset position) => setState(() => cartPosition = position);

  void movePhoto(Offset position) => setState(() => photoPosition = position);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: photoPosition.dx,
            top: photoPosition.dy,
            width: 96,
            height: 80,
            child: CartAnimationAnchor(
              key: anchorKey,
              child: const ColoredBox(
                key: _photoKey,
                color: Colors.orange,
                child: Center(child: Text('Selected pizza')),
              ),
            ),
          ),
          Positioned(
            left: cartPosition.dx,
            top: cartPosition.dy,
            width: 32,
            height: 32,
            child: SizedBox(
              key: cartKey,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          Positioned(
            left: 300,
            top: 60,
            child: TextButton(
              key: const ValueKey('unrelated-control'),
              onPressed: () => otherTaps++,
              child: const Text('Keep shopping'),
            ),
          ),
        ],
      ),
    ),
  );
}
