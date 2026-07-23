import 'dart:async';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';
import 'package:enjoy_lavash_mobile/theme/dark_theme.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';

class InitialLocationLoader extends StatefulWidget {
  const InitialLocationLoader({required this.child, super.key});

  final Widget child;

  @override
  State<InitialLocationLoader> createState() => _InitialLocationLoaderState();
}

class _InitialLocationLoaderState extends State<InitialLocationLoader>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<LocationController>().requestPermissionAndLocate(),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    unawaited(
      context.read<MobileBackendController>().handleAppResumed(
        locale: context.read<LocaleController>().locale.languageCode,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().themeMode;
    final locale = context.watch<LocaleController>().locale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Enjoy Lavash',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainTabs(),
    );
  }
}
