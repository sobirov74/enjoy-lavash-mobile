import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:enjoy_lavash_mobile/app/di.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/features/app_version/presentation/app_version_gate.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';
import 'package:enjoy_lavash_mobile/theme/dark_theme.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.versionRepository});

  final MobileBackendRepository? versionRepository;

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().themeMode;
    final locale = context.watch<LocaleController>().locale;
    final repository =
        versionRepository ??
        (sl.isRegistered<MobileBackendRepository>()
            ? sl<MobileBackendRepository>()
            : null);

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
      home: repository == null
          ? const MainTabs()
          : AppVersionGate(
              repository: repository,
              languageCode: locale.languageCode,
              child: const MainTabs(),
            ),
    );
  }
}
