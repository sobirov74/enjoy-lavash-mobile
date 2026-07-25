import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('closes a scrollable modal when dragged downward', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    enableDrag: false,
                    showDragHandle: false,
                    builder: (_) => const SizedBox(
                      height: 600,
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            AppBottomSheetDragHandle(),
                            Text('Scrollable sheet content'),
                            SizedBox(height: 900),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Scrollable sheet content'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey<String>('bottom-sheet-drag-handle')),
      const Offset(0, 100),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scrollable sheet content'), findsNothing);
  });

  testWidgets('does not close when dragged upward', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    enableDrag: false,
                    showDragHandle: false,
                    builder: (_) => const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppBottomSheetDragHandle(),
                        Text('Sheet stays open'),
                      ],
                    ),
                  );
                },
                child: const Text('Open sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey<String>('bottom-sheet-drag-handle')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sheet stays open'), findsOneWidget);
  });
}
