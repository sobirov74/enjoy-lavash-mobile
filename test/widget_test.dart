// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeController>(
        create: (_) => ThemeController(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EnjoyLavash'), findsOneWidget);
    expect(find.text('Меню'), findsOneWidget);
  });
}
