import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cart Undo snack closes itself after its visible countdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      _snackHost(
        onShow: (messenger) {
          showAutoClosingAppSnackBar(
            messenger,
            'Lavash removed from cart',
            duration: const Duration(milliseconds: 600),
            actionLabel: 'Undo',
            onAction: () {},
          );
        },
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Undo restores immediately and closes the snack', (tester) async {
    var undoCalls = 0;
    await tester.pumpWidget(
      _snackHost(
        onShow: (messenger) {
          showAutoClosingAppSnackBar(
            messenger,
            'Lavash removed from cart',
            actionLabel: 'Undo',
            onAction: () => undoCalls += 1,
          );
        },
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();

    expect(undoCalls, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('cart Undo snack uses a light-mode surface', (tester) async {
    await tester.pumpWidget(
      _snackHost(
        onShow: (messenger) {
          showAutoClosingAppSnackBar(
            messenger,
            'Lavash removed from cart',
            actionLabel: 'Undo',
            onAction: () {},
          );
        },
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));

    expect(snack.backgroundColor, Colors.white);
    expect(action.textColor, BaseColors.primaryDark);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('auto-close still applies with accessible navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _snackHost(
        accessibleNavigation: true,
        onShow: (messenger) {
          showAutoClosingAppSnackBar(
            messenger,
            'Lavash removed from cart',
            duration: const Duration(milliseconds: 400),
            actionLabel: 'Undo',
            onAction: () {},
          );
        },
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
}

Widget _snackHost({
  required void Function(ScaffoldMessengerState messenger) onShow,
  bool accessibleNavigation = false,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(accessibleNavigation: accessibleNavigation),
      child: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => onShow(ScaffoldMessenger.of(context)),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    ),
  );
}
