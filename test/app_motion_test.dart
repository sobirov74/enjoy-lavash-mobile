import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppMotion', () {
    testWidgets('keeps the requested duration for normal motion', (
      tester,
    ) async {
      late bool reduced;
      late Duration duration;

      await tester.pumpWidget(
        _motionHost(
          child: Builder(
            builder: (context) {
              reduced = AppMotion.reduced(context);
              duration = AppMotion.duration(context, AppMotion.spatial);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(reduced, isFalse);
      expect(duration, AppMotion.spatial);
    });

    testWidgets('reduces motion when animations are disabled', (tester) async {
      late bool reduced;
      late Duration duration;

      await tester.pumpWidget(
        _motionHost(
          disableAnimations: true,
          child: Builder(
            builder: (context) {
              reduced = AppMotion.reduced(context);
              duration = AppMotion.duration(context, AppMotion.spatial);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(reduced, isTrue);
      expect(duration, Duration.zero);
    });

    testWidgets('reduces motion for accessible navigation', (tester) async {
      late bool reduced;

      await tester.pumpWidget(
        _motionHost(
          accessibleNavigation: true,
          child: Builder(
            builder: (context) {
              reduced = AppMotion.reduced(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(reduced, isTrue);
    });
  });

  group('reduced-motion entrances', () {
    testWidgets('FadeSlideIn skips travel and its stagger delay', (
      tester,
    ) async {
      await tester.pumpWidget(
        _motionHost(
          disableAnimations: true,
          child: const FadeSlideIn(
            delay: Duration(seconds: 1),
            beginOffset: Offset(0, 0.5),
            child: Text('Menu'),
          ),
        ),
      );

      final entrance = find.byType(FadeSlideIn);
      final fade = tester.widget<FadeTransition>(
        find.descendant(of: entrance, matching: find.byType(FadeTransition)),
      );
      final slide = tester.widget<SlideTransition>(
        find.descendant(of: entrance, matching: find.byType(SlideTransition)),
      );
      expect(fade.opacity.value, 1);
      expect(slide.position.value, Offset.zero);
    });

    testWidgets('FadeIndexedStack does not animate a tab change', (
      tester,
    ) async {
      Widget buildStack(int index) {
        return _motionHost(
          accessibleNavigation: true,
          child: FadeIndexedStack(
            index: index,
            children: const [Text('Menu'), Text('Cart')],
          ),
        );
      }

      await tester.pumpWidget(buildStack(0));
      await tester.pumpWidget(buildStack(1));

      final stack = find.byType(FadeIndexedStack);
      final fade = tester.widget<FadeTransition>(
        find.descendant(of: stack, matching: find.byType(FadeTransition)),
      );
      final slide = tester.widget<SlideTransition>(
        find.descendant(of: stack, matching: find.byType(SlideTransition)),
      );
      expect(fade.opacity.value, 1);
      expect(slide.position.value, Offset.zero);
      expect(find.text('Cart'), findsOneWidget);
    });
  });
}

Widget _motionHost({
  required Widget child,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
      ),
      child: Scaffold(body: child),
    ),
  );
}
