import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController();
  final localeController = LocaleController();

  await Future.wait([
    themeController.loadTheme(),
    localeController.loadLocale(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
      ],
      child: const MyApp(),
    ),
  );
}
