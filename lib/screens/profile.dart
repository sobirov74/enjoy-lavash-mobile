import 'dart:async';

import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/confirm_dialog.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/external_url_launcher.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late final Future<String?> _appVersionFuture;

  @override
  void initState() {
    super.initState();
    _appVersionFuture = _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context
            .read<MobileBackendController>()
            .refreshPushNotificationSettings(),
      );
    });
  }

  Future<void> _shareApp(L t) async {
    await SharePlus.instance.share(ShareParams(text: t.shareAppText));
  }

  Future<String?> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();
      if (version.isEmpty) return null;
      if (buildNumber.isEmpty) return version;
      return version;
    } catch (error) {
      debugPrint('App version lookup failed: $error');
      return null;
    }
  }

  void _confirmLogout(BuildContext context, L t) {
    showConfirmDialog(
      context: context,
      title: t.logoutTitle,
      confirmText: t.logout,
      cancelText: t.no,
      footerReversed: true,
      onCancel: () {},
      onConfirm: () => unawaited(_logout(context, t)),
      child: TypographyText(
        t.logoutMessage,
        style: const TextStyle(color: BaseColors.textGray, fontSize: 14),
      ),
    );
  }

  Future<void> _logout(BuildContext context, L t) async {
    final result = await context.read<MobileBackendController>().logout();
    if (!context.mounted || result.isSuccess) return;

    ScaffoldMessenger.of(context).showSnackBar(
      appSnackBar(result.failureOrNull?.message ?? t.logoutFailed),
    );
  }

  Future<void> _showDeleteAccountSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeleteAccountSheet(),
    );
  }

  Future<void> _showAuthorizationModal(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: const AuthorizationScreen(),
          ),
        );
      },
    );
  }

  void _openAllOrders(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _AllOrdersScreen()));
  }

  Future<void> _setPushNotifications(BuildContext context, bool enabled) async {
    final t = L.of(context);
    final result = await context
        .read<MobileBackendController>()
        .setPushNotificationsEnabled(enabled);

    if (!context.mounted) return;

    switch (result) {
      case Success(:final data):
        if (enabled && !data.enabled) {
          final message = data.permissionPermanentlyDenied
              ? _orderText(
                  t,
                  en: 'Allow notifications in phone settings',
                  ru: 'Разрешите уведомления в настройках телефона',
                  uz: 'Telefon sozlamalarida bildirishnomalarga ruxsat bering',
                )
              : _orderText(
                  t,
                  en: 'Notification permission was not allowed',
                  ru: 'Разрешение на уведомления не выдано',
                  uz: 'Bildirishnomalarga ruxsat berilmadi',
                );
          ScaffoldMessenger.of(context).showSnackBar(appSnackBar(message));
        }
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(
            failure.message.isNotEmpty
                ? failure.message
                : _orderText(
                    t,
                    en: 'Could not update notification settings',
                    ru: 'Не удалось обновить настройки уведомлений',
                    uz: "Bildirishnoma sozlamalarini yangilab bo'lmadi",
                  ),
          ),
        );
    }
  }

  String _formatAddress(ClientAddress address) {
    final parts = <String>[address.street];
    if (address.houseNumber?.isNotEmpty == true) {
      parts.add(address.houseNumber!);
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeController = context.read<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final mobileBackend = context.watch<MobileBackendController>();
    final t = L.of(context);
    final client = mobileBackend.client;
    final isAuthorized = client != null;
    final displayName = client?.fullName.isNotEmpty == true
        ? client!.fullName
        : (isAuthorized ? t.guest : t.authorization);
    final phoneNumber = client?.phoneNumber.isNotEmpty == true
        ? client!.phoneNumber
        : '';
    final profileSubtitle = phoneNumber.isNotEmpty
        ? phoneNumber
        : t.tapToSignIn;
    final recentOrders = mobileBackend.orders.take(2).toList(growable: false);
    final hasMoreOrders = mobileBackend.orders.length > recentOrders.length;
    final backendFailure = mobileBackend.failure;
    final pushSettings = mobileBackend.pushNotificationSettings;
    final notificationsLoading = mobileBackend.pushNotificationsUpdating;
    final notificationsSupported = pushSettings?.supported ?? true;
    final notificationsEnabled = pushSettings?.enabled ?? false;

    return RefreshIndicator(
      color: BaseColors.primary,
      onRefresh: widget.onRefresh ?? () async {},
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TypographyText(
                    t.profile,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    child: GestureDetector(
                      onTap: isAuthorized
                          ? null
                          : () => unawaited(_showAuthorizationModal(context)),
                      child: _SurfaceCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 76,
                              height: 76,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color(0xFFFFC107),
                                    BaseColors.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(24),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                    ),
                                child: Icon(
                                  isAuthorized
                                      ? Icons.person_rounded
                                      : Icons.login_rounded,
                                  key: ValueKey<bool>(isAuthorized),
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  TypographyText(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TypographyText(
                                    profileSubtitle,
                                    style: const TextStyle(
                                      color: BaseColors.textGray,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isAuthorized)
                              const Icon(Icons.chevron_right_rounded, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (backendFailure != null) ...[
                    AnimatedErrorMessage(
                      failure: backendFailure,
                      compact: true,
                      onRetry: widget.onRefresh == null
                          ? null
                          : () => unawaited(widget.onRefresh!()),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // -- Settings
                  _SectionCard(
                    isDark: isDark,
                    title: t.settings,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _NotificationSwitchTile(
                          isDark: isDark,
                          title: _orderText(
                            t,
                            en: 'Notifications',
                            ru: 'Уведомления',
                            uz: 'Bildirishnomalar',
                          ),
                          subtitle: _notificationSubtitle(
                            t,
                            isLoading: pushSettings == null,
                            supported: notificationsSupported,
                            enabled: notificationsEnabled,
                            permissionPermanentlyDenied:
                                pushSettings?.permissionPermanentlyDenied ??
                                false,
                          ),
                          value: notificationsEnabled,
                          loading: notificationsLoading,
                          enabled:
                              pushSettings != null &&
                              notificationsSupported &&
                              !mobileBackend.pushNotificationsUpdating,
                          onChanged: (value) =>
                              unawaited(_setPushNotifications(context, value)),
                        ),
                        const _SettingsDivider(),
                        _SettingsHeader(
                          icon: Icons.palette_outlined,
                          title: _orderText(
                            t,
                            en: 'Appearance',
                            ru: 'Оформление',
                            uz: "Ko'rinish",
                          ),
                          subtitle: _orderText(
                            t,
                            en: 'Choose the app color mode',
                            ru: 'Выберите цветовой режим приложения',
                            uz: 'Ilova rang rejimini tanlang',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _PreferenceChip(
                                label: t.lightTheme,
                                icon: Icons.light_mode_rounded,
                                isActive: !isDark,
                                isDark: isDark,
                                onTap: () =>
                                    themeController.setTheme(ThemeMode.light),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PreferenceChip(
                                label: t.darkTheme,
                                icon: Icons.dark_mode_rounded,
                                isActive: isDark,
                                isDark: isDark,
                                onTap: () =>
                                    themeController.setTheme(ThemeMode.dark),
                              ),
                            ),
                          ],
                        ),
                        const _SettingsDivider(),
                        _SettingsHeader(
                          icon: Icons.translate_rounded,
                          title: _orderText(
                            t,
                            en: 'Language',
                            ru: 'Язык',
                            uz: 'Til',
                          ),
                          subtitle: _orderText(
                            t,
                            en: 'Use the app in your preferred language',
                            ru: 'Используйте приложение на удобном языке',
                            uz: 'Ilovadan qulay tilda foydalaning',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            for (final entry in [
                              (locale: const Locale('uz'), label: "O'zbekcha"),
                              (locale: const Locale('ru'), label: 'Русский'),
                              (locale: const Locale('en'), label: 'English'),
                            ]) ...[
                              if (entry.locale != const Locale('uz'))
                                const SizedBox(width: 8),
                              Expanded(
                                child: _LangChip(
                                  label: entry.label,
                                  isActive:
                                      localeController.locale == entry.locale,
                                  isDark: isDark,
                                  onTap: () =>
                                      localeController.setLocale(entry.locale),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Loyalty card
                  // Container(
                  //   padding: const EdgeInsets.all(22),
                  //   decoration: BoxDecoration(
                  //     gradient: const LinearGradient(
                  //       colors: <Color>[BaseColors.primary, Color(0xFFFF7043)],
                  //       begin: Alignment.topLeft,
                  //       end: Alignment.bottomRight,
                  //     ),
                  //     borderRadius: BorderRadius.circular(30),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: <Widget>[
                  //       TypographyText(
                  //         t.loyaltyCard,
                  //         style: const TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 22,
                  //           fontWeight: FontWeight.w800,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 6),
                  //       TypographyText(
                  //         t.accumulatedPoints,
                  //         style: const TextStyle(
                  //           color: Colors.white70,
                  //           fontSize: 15,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 18),
                  //       TypographyText(
                  //         _formatPoints(loyaltyPoints),
                  //         style: const TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 42,
                  //           fontWeight: FontWeight.w900,
                  //           letterSpacing: 0,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 18),
                  //       Container(
                  //         width: double.infinity,
                  //         padding: const EdgeInsets.all(18),
                  //         decoration: BoxDecoration(
                  //           color: Colors.white,
                  //           borderRadius: BorderRadius.circular(26),
                  //         ),
                  //         child: Column(
                  //           children: <Widget>[
                  //             Icon(
                  //               Icons.qr_code_2_rounded,
                  //               size: 180,
                  //               color: Colors.grey.shade900,
                  //             ),
                  //             const SizedBox(height: 8),
                  //             TypographyText(
                  //               'ENJOY-LAVASH-$loyaltyPoints',
                  //               style: const TextStyle(
                  //                 letterSpacing: 2.4,
                  //                 fontSize: 12,
                  //                 fontWeight: FontWeight.w700,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //       const SizedBox(height: 14),
                  //       TypographyText(
                  //         t.showCodeForPoints,
                  //         style: const TextStyle(
                  //           color: Colors.white70,
                  //           fontSize: 14,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 16),

                  // -- Personal info
                  if (isAuthorized)
                    FadeSlideIn(
                      child: _SectionCard(
                        isDark: isDark,
                        title: t.personalInfo,
                        child: Column(
                          children: <Widget>[
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              title: t.phoneNumber,
                              value: client.phoneNumber,
                            ),
                            if (mobileBackend.addresses.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _InfoRow(
                                icon: Icons.location_on_outlined,
                                title: t.address,
                                value: _formatAddress(
                                  mobileBackend.addresses.first,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  if (isAuthorized) const SizedBox(height: 16),

                  // -- Order history
                  if (mobileBackend.orders.isNotEmpty) ...[
                    FadeSlideIn(
                      child: _SectionCard(
                        isDark: isDark,
                        title: t.orderHistory,
                        padding: const EdgeInsets.all(14),
                        titleBottomSpacing: 12,
                        child: Column(
                          children: <Widget>[
                            for (int i = 0; i < recentOrders.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              _OrderRow(
                                order: recentOrders[i],
                                locale: localeController.locale.languageCode,
                                branches: mobileBackend.branches,
                                addresses: mobileBackend.addresses,
                              ),
                            ],
                            if (hasMoreOrders) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: BaseColors.primary,
                                    side: const BorderSide(
                                      color: BaseColors.primary,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () => _openAllOrders(context),
                                  icon: const Icon(Icons.receipt_long_rounded),
                                  label: TypographyText(
                                    _orderText(
                                      t,
                                      en: 'See all orders',
                                      ru: 'Все заказы',
                                      uz: "Barcha buyurtmalar",
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // -- Cashback system
                  _SectionCard(
                    isDark: isDark,
                    title: t.cashbackSystem,
                    child: Column(
                      children: <Widget>[
                        _StatLine(label: t.perOrder, value: t.perOrderValue),
                        const SizedBox(height: 10),
                        _StatLine(
                          label: t.onePointEquals,
                          value: t.onePointValue,
                        ),
                        const SizedBox(height: 10),
                        _StatLine(label: t.canSpend, value: t.canSpendValue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Actions
                  _SectionCard(
                    isDark: isDark,
                    title: _orderText(
                      t,
                      en: 'Actions',
                      ru: 'Действия',
                      uz: 'Amallar',
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BaseColors.primary,
                              side: const BorderSide(color: BaseColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => _shareApp(t),
                            icon: const Icon(Icons.share_outlined),
                            label: TypographyText(t.shareApp),
                          ),
                        ),
                        if (client != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: BaseColors.danger,
                                side: const BorderSide(
                                  color: BaseColors.danger,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () => _confirmLogout(context, t),
                              icon: const Icon(Icons.logout_rounded),
                              label: TypographyText(t.logout),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? BaseColors.dangerDark
                                    : BaseColors.danger,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () =>
                                  unawaited(_showDeleteAccountSheet(context)),
                              icon: const Icon(
                                Icons.delete_forever_outlined,
                                size: 20,
                              ),
                              label: TypographyText(
                                _orderText(
                                  t,
                                  en: 'Delete account',
                                  ru: 'Удалить аккаунт',
                                  uz: "Hisobni o'chirish",
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const _SettingsDivider(),
                        _AppVersionRow(
                          future: _appVersionFuture,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  bool _acknowledged = false;

  Future<void> _deleteAccount(BuildContext context, L t) async {
    final controller = context.read<MobileBackendController>();
    if (controller.accountDeleting) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.deleteAccount();

    if (!mounted) return;

    switch (result) {
      case Success():
        navigator.pop();
        messenger.showSnackBar(
          appSnackBar(
            _orderText(
              t,
              en: 'Your account has been deleted',
              ru: 'Ваш аккаунт удалён',
              uz: "Hisobingiz o'chirildi",
            ),
          ),
        );
      case Error(:final failure):
        messenger.showSnackBar(
          appSnackBar(
            failure.message.isNotEmpty
                ? failure.message
                : _orderText(
                    t,
                    en: 'Could not delete the account. Please try again.',
                    ru: 'Не удалось удалить аккаунт. Попробуйте ещё раз.',
                    uz: "Hisobni o'chirib bo'lmadi. Qayta urinib ko'ring.",
                  ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = L.of(context);
    final deleting = context.watch<MobileBackendController>().accountDeleting;
    final danger = isDark ? BaseColors.dangerDark : BaseColors.danger;

    return PopScope(
      canPop: !deleting,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1A18) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            22 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4A4038)
                        : const Color(0xFFE5DAD0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: danger.withValues(alpha: isDark ? 0.22 : 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: danger,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          _orderText(
                            t,
                            en: 'Delete account?',
                            ru: 'Удалить аккаунт?',
                            uz: "Hisob o'chirilsinmi?",
                          ),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TypographyText(
                          _orderText(
                            t,
                            en:
                                'This action is permanent and cannot be '
                                'undone',
                            ru:
                                'Это действие необратимо — восстановить '
                                'данные не получится',
                            uz: "Bu amalni ortga qaytarib bo'lmaydi",
                          ),
                          style: TextStyle(
                            color: isDark
                                ? BaseColors.lightTextGray
                                : BaseColors.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: deleting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2522)
                      : const Color(0xFFF8F4EF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TypographyText(
                      _orderText(
                        t,
                        en: 'The following will be deleted:',
                        ru: 'Будут удалены:',
                        uz: "Quyidagilar o'chiriladi:",
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DeleteImpactRow(
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      text: _orderText(
                        t,
                        en: 'Profile and phone number',
                        ru: 'Профиль и номер телефона',
                        uz: 'Profil va telefon raqami',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DeleteImpactRow(
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                      text: _orderText(
                        t,
                        en: 'Saved delivery addresses',
                        ru: 'Сохранённые адреса доставки',
                        uz: 'Saqlangan yetkazib berish manzillari',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DeleteImpactRow(
                      icon: Icons.receipt_long_outlined,
                      isDark: isDark,
                      text: _orderText(
                        t,
                        en: 'Order history',
                        ru: 'История заказов',
                        uz: 'Buyurtmalar tarixi',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DeleteImpactRow(
                      icon: Icons.stars_rounded,
                      isDark: isDark,
                      text: _orderText(
                        t,
                        en: 'Accumulated bonus points',
                        ru: 'Накопленные бонусные баллы',
                        uz: "To'plangan bonus ballari",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: deleting
                    ? null
                    : () => setState(() => _acknowledged = !_acknowledged),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: isDark ? 0.12 : 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: danger.withValues(
                        alpha: _acknowledged ? 0.55 : 0.25,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Checkbox(
                        value: _acknowledged,
                        activeColor: danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: deleting
                            ? null
                            : (value) => setState(
                                () => _acknowledged = value ?? false,
                              ),
                      ),
                      Expanded(
                        child: TypographyText(
                          _orderText(
                            t,
                            en:
                                'I understand that my data will be deleted '
                                'permanently',
                            ru:
                                'Я понимаю, что мои данные будут удалены '
                                'безвозвратно',
                            uz:
                                "Ma'lumotlarim butunlay o'chirilishini "
                                'tushunaman',
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: danger.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _acknowledged && !deleting
                      ? () => unawaited(_deleteAccount(context, t))
                      : null,
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white70,
                          ),
                        )
                      : const Icon(Icons.delete_forever_rounded, size: 20),
                  label: TypographyText(
                    deleting
                        ? _orderText(
                            t,
                            en: 'Deleting…',
                            ru: 'Удаляем…',
                            uz: "O'chirilmoqda…",
                          )
                        : _orderText(
                            t,
                            en: 'Delete my account',
                            ru: 'Удалить мой аккаунт',
                            uz: "Hisobimni o'chirish",
                          ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: deleting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: TypographyText(
                    _orderText(
                      t,
                      en: 'Cancel',
                      ru: 'Отмена',
                      uz: 'Bekor qilish',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteImpactRow extends StatelessWidget {
  const _DeleteImpactRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 20,
          color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TypographyText(
            text,
            style: TextStyle(
              color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _AllOrdersScreen extends StatefulWidget {
  const _AllOrdersScreen();

  @override
  State<_AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<_AllOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  MobileOrderType? _typeFilter;
  MobileOrderStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerOrderModel> _filteredOrders({
    required List<CustomerOrderModel> orders,
    required List<BranchModel> branches,
    required List<ClientAddress> addresses,
    required L t,
  }) {
    final query = _query.trim().toLowerCase();

    return orders
        .where((order) {
          if (_typeFilter != null && order.type != _typeFilter) return false;
          if (_statusFilter != null && order.status != _statusFilter) {
            return false;
          }
          if (query.isEmpty) return true;

          final destination =
              _orderDestination(order, branches, addresses, t) ?? '';
          final products = order.items
              .map((item) => _orderProductTitle(item, t))
              .join(' ');
          final haystack = <String>[
            order.id,
            _shortOrderId(order.id),
            _statusLabel(order.status, t),
            _orderTypeLabel(order.type, t),
            _formatOrderAmount(order.totalAmount),
            destination,
            products,
          ].join(' ').toLowerCase();

          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final locale = context.watch<LocaleController>().locale.languageCode;
    final backend = context.watch<MobileBackendController>();
    final orders = backend.orders;
    final statuses = ({for (final order in orders) order.status}.toList()
      ..sort((a, b) => a.index.compareTo(b.index)));
    final filteredOrders = _filteredOrders(
      orders: orders,
      branches: backend.branches,
      addresses: backend.addresses,
      t: t,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: TypographyText(
                      _orderText(
                        t,
                        en: 'All orders',
                        ru: 'Все заказы',
                        uz: 'Barcha buyurtmalar',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BaseColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: TypographyText(
                      '${filteredOrders.length}/${orders.length}',
                      style: const TextStyle(
                        color: BaseColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _OrdersSearchField(
                controller: _searchController,
                isDark: isDark,
                hintText: _orderText(
                  t,
                  en: 'Search by product, status, or order ID',
                  ru: 'Поиск по товару, статусу или номеру',
                  uz: 'Mahsulot, holat yoki buyurtma raqami',
                ),
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  _OrderFilterChip(
                    label: _orderText(t, en: 'All', ru: 'Все', uz: 'Barchasi'),
                    selected: _typeFilter == null,
                    onTap: () => setState(() => _typeFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _OrderFilterChip(
                    label: t.delivery,
                    selected: _typeFilter == MobileOrderType.delivery,
                    onTap: () =>
                        setState(() => _typeFilter = MobileOrderType.delivery),
                  ),
                  const SizedBox(width: 8),
                  _OrderFilterChip(
                    label: t.pickup,
                    selected: _typeFilter == MobileOrderType.pickup,
                    onTap: () =>
                        setState(() => _typeFilter = MobileOrderType.pickup),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: statuses.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _OrderFilterChip(
                      label: _orderText(
                        t,
                        en: 'Any status',
                        ru: 'Любой статус',
                        uz: 'Har qanday holat',
                      ),
                      selected: _statusFilter == null,
                      onTap: () => setState(() => _statusFilter = null),
                    );
                  }

                  final status = statuses[index - 1];
                  return _OrderFilterChip(
                    label: _statusLabel(status, t),
                    selected: _statusFilter == status,
                    onTap: () => setState(() => _statusFilter = status),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: backend.failure != null && orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      child: Center(
                        child: AnimatedErrorMessage(
                          failure: backend.failure,
                          onRetry: () => unawaited(
                            context
                                .read<MobileBackendController>()
                                .refreshCustomerData(),
                          ),
                        ),
                      ),
                    )
                  : filteredOrders.isEmpty
                  ? _OrdersEmptyState(isDark: isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _OrderRow(
                          order: filteredOrders[index],
                          locale: locale,
                          branches: backend.branches,
                          addresses: backend.addresses,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersSearchField extends StatelessWidget {
  const _OrdersSearchField({
    required this.controller,
    required this.isDark,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isDark;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasQuery = value.text.trim().isNotEmpty;

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D1A18) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.search_rounded,
                color: BaseColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  cursorColor: BaseColors.primary,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF9E9790)
                          : BaseColors.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (hasQuery)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        );
      },
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  const _OrderFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      label: TypographyText(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected || isDark ? Colors.white : const Color(0xFF14110F),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
      backgroundColor: isDark
          ? const Color(0xFF201C19)
          : const Color(0xFFF1EDE7),
      selectedColor: BaseColors.primary,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.receipt_long_outlined,
              size: 46,
              color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
            ),
            const SizedBox(height: 14),
            TypographyText(
              _orderText(
                t,
                en: 'No orders match your filters',
                ru: 'Нет заказов по выбранным фильтрам',
                uz: "Filtrlarga mos buyurtma yo'q",
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language chip button
// ---------------------------------------------------------------------------

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? BaseColors.primary
              : (isDark ? BaseColors.black600 : const Color(0xFFF3F0EB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TypographyText(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF14110F)),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final bool value;
  final bool loading;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: BaseColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              TypographyText(
                subtitle,
                style: TextStyle(
                  color: isDark
                      ? BaseColors.lightTextGray
                      : BaseColors.textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey<String>('loading'),
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: BaseColors.primary,
                  ),
                )
              : Switch.adaptive(
                  key: const ValueKey<String>('switch'),
                  value: value,
                  activeThumbColor: BaseColors.primary,
                  onChanged: enabled ? onChanged : null,
                ),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: <Widget>[
        Icon(icon, color: BaseColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              TypographyText(
                subtitle,
                style: TextStyle(
                  color: isDark
                      ? BaseColors.lightTextGray
                      : BaseColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        height: 1,
        color: isDark ? BaseColors.borderDark : BaseColors.borderLight,
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF14110F));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? BaseColors.primary
              : (isDark ? BaseColors.black600 : const Color(0xFFF3F0EB)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: TypographyText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppVersionRow extends StatelessWidget {
  const _AppVersionRow({required this.future, required this.isDark});

  final Future<String?> future;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: BaseColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: TypographyText(
            _orderText(
              t,
              en: 'App version',
              ru: 'Версия приложения',
              uz: 'Ilova versiyasi',
            ),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        FutureBuilder<String?>(
          future: future,
          builder: (context, snapshot) {
            final version = snapshot.data;
            return TypographyText(
              version?.isNotEmpty == true ? version! : '...',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable private widgets
// ---------------------------------------------------------------------------

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.child,
    this.padding,
    this.titleBottomSpacing = 16,
  });

  final bool isDark;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double titleBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      isDark: isDark,
      padding: padding ?? const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TypographyText(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: titleBottomSpacing),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.surfaceTint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: BaseColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                title,
                style: const TextStyle(
                  color: BaseColors.textGray,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              TypographyText(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _orderText(
  L t, {
  required String en,
  required String ru,
  required String uz,
}) {
  return switch (t.localeName.split('_').first) {
    'ru' => ru,
    'uz' => uz,
    _ => en,
  };
}

String _notificationSubtitle(
  L t, {
  required bool isLoading,
  required bool supported,
  required bool enabled,
  required bool permissionPermanentlyDenied,
}) {
  if (isLoading) {
    return _orderText(
      t,
      en: 'Checking notification permission',
      ru: 'Проверяем доступ к уведомлениям',
      uz: 'Bildirishnoma ruxsati tekshirilmoqda',
    );
  }
  if (!supported) {
    return _orderText(
      t,
      en: 'Notifications are not available on this device',
      ru: 'Уведомления недоступны на этом устройстве',
      uz: 'Bu qurilmada bildirishnomalar mavjud emas',
    );
  }
  if (enabled) {
    return _orderText(
      t,
      en: 'Order updates and offers are enabled',
      ru: 'Статусы заказов и акции включены',
      uz: 'Buyurtma holati va aksiyalar yoqilgan',
    );
  }
  if (permissionPermanentlyDenied) {
    return _orderText(
      t,
      en: 'Allow notifications in phone settings',
      ru: 'Разрешите уведомления в настройках телефона',
      uz: 'Telefon sozlamalarida bildirishnomalarga ruxsat bering',
    );
  }
  return _orderText(
    t,
    en: 'Receive order updates and special offers',
    ru: 'Получайте статусы заказов и специальные предложения',
    uz: 'Buyurtma holati va maxsus takliflarni oling',
  );
}

String _formatOrderAmount(int amount) {
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(text[i]);
  }
  buffer.write(" so'm");
  return buffer.toString();
}

String _formatOrderDate(DateTime? date, String locale) {
  if (date == null) return '';
  return DateFormat.yMMMMd(locale).format(date.toLocal());
}

String _formatOrderDateTime(DateTime? date, String locale) {
  if (date == null) return '';
  return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
}

String _shortOrderId(String id) {
  final value = id.trim();
  if (value.length <= 8) return value;
  return value.substring(value.length - 8).toUpperCase();
}

String _statusLabel(MobileOrderStatus status, L t) {
  return switch (status) {
    MobileOrderStatus.newOrder => t.statusNew,
    MobileOrderStatus.confirmed => t.statusAccepted,
    MobileOrderStatus.cooking => _orderText(
      t,
      en: 'Cooking',
      ru: 'Готовится',
      uz: 'Tayyorlanmoqda',
    ),
    MobileOrderStatus.ready => _orderText(
      t,
      en: 'Ready',
      ru: 'Готов',
      uz: 'Tayyor',
    ),
    MobileOrderStatus.courierAssigned => _orderText(
      t,
      en: 'Courier assigned',
      ru: 'Курьер назначен',
      uz: 'Kuryer biriktirildi',
    ),
    MobileOrderStatus.onTheWay => _orderText(
      t,
      en: 'On the way',
      ru: 'В пути',
      uz: "Yo'lda",
    ),
    MobileOrderStatus.delivered => t.statusCompleted,
    MobileOrderStatus.cancelled => t.statusCancelled,
    MobileOrderStatus.refunded => t.statusFailed,
    MobileOrderStatus.unknown => _orderText(
      t,
      en: 'Unknown',
      ru: 'Неизвестно',
      uz: "Noma'lum",
    ),
  };
}

({Color bg, Color text}) _statusColors(MobileOrderStatus status) {
  return switch (status) {
    MobileOrderStatus.delivered || MobileOrderStatus.ready => (
      bg: const Color(0xFFE7F6EA),
      text: BaseColors.success,
    ),
    MobileOrderStatus.cancelled || MobileOrderStatus.refunded => (
      bg: const Color(0xFFFDE8E8),
      text: BaseColors.danger,
    ),
    MobileOrderStatus.unknown => (
      bg: const Color(0xFFEDEAE6),
      text: BaseColors.textGray,
    ),
    _ => (bg: const Color(0xFFFFF3E0), text: const Color(0xFFE65100)),
  };
}

({Color bg, Color border, Color accent}) _statusSurfaceColors(
  MobileOrderStatus status,
  bool isDark,
) {
  final accent = switch (status) {
    MobileOrderStatus.newOrder => const Color(0xFF3B82F6),
    MobileOrderStatus.confirmed => const Color(0xFF22C55E),
    MobileOrderStatus.cooking => const Color(0xFFF59E0B),
    MobileOrderStatus.ready => const Color(0xFF10B981),
    MobileOrderStatus.courierAssigned => const Color(0xFF38BDF8),
    MobileOrderStatus.onTheWay => const Color(0xFF6366F1),
    MobileOrderStatus.delivered => const Color(0xFF16A34A),
    MobileOrderStatus.cancelled => BaseColors.danger,
    MobileOrderStatus.refunded => const Color(0xFFEC4899),
    MobileOrderStatus.unknown => BaseColors.textGray,
  };
  final base = isDark ? const Color(0xFF2A2522) : Colors.white;

  return (
    bg: Color.alphaBlend(accent.withValues(alpha: isDark ? 0.18 : 0.09), base),
    border: accent.withValues(alpha: isDark ? 0.36 : 0.22),
    accent: accent,
  );
}

String _orderTypeLabel(MobileOrderType type, L t) {
  return switch (type) {
    MobileOrderType.delivery => t.delivery,
    MobileOrderType.pickup => t.pickup,
  };
}

IconData _orderTypeIcon(MobileOrderType type) {
  return switch (type) {
    MobileOrderType.delivery => Icons.delivery_dining_rounded,
    MobileOrderType.pickup => Icons.store_mall_directory_rounded,
  };
}

String _paymentMethodLabel(MobilePaymentMethod method, L t) {
  return switch (method) {
    MobilePaymentMethod.cash => _orderText(
      t,
      en: 'Cash',
      ru: 'Наличные',
      uz: 'Naqd',
    ),
    MobilePaymentMethod.cardTerminal => _orderText(
      t,
      en: 'Card terminal',
      ru: 'Терминал',
      uz: 'Terminal',
    ),
    MobilePaymentMethod.payme => 'Payme',
    MobilePaymentMethod.click => 'Click',
    MobilePaymentMethod.unknown => _orderText(
      t,
      en: 'Unknown',
      ru: 'Неизвестно',
      uz: "Noma'lum",
    ),
  };
}

String _paymentStatusLabel(MobilePaymentStatus status, L t) {
  return switch (status) {
    MobilePaymentStatus.pending => _orderText(
      t,
      en: 'Pending',
      ru: 'Ожидает оплаты',
      uz: 'Kutilmoqda',
    ),
    MobilePaymentStatus.paid => _orderText(
      t,
      en: 'Paid',
      ru: 'Оплачено',
      uz: "To'langan",
    ),
    MobilePaymentStatus.failed => _orderText(
      t,
      en: 'Failed',
      ru: 'Не оплачено',
      uz: "To'lanmadi",
    ),
    MobilePaymentStatus.refunded => _orderText(
      t,
      en: 'Refunded',
      ru: 'Возвращено',
      uz: 'Qaytarilgan',
    ),
    MobilePaymentStatus.unknown => _orderText(
      t,
      en: 'Unknown',
      ru: 'Неизвестно',
      uz: "Noma'lum",
    ),
  };
}

String _orderProductTitle(CustomerOrderItemModel item, L t) {
  final language = t.localeName.split('_').first;
  final name = item.localizedName(language);
  if (name != null && name.isNotEmpty) return name;

  final productId = item.productId.trim();
  final fallback = _orderText(t, en: 'Product', ru: 'Товар', uz: 'Mahsulot');
  if (productId.isEmpty) return fallback;
  return '$fallback $productId';
}

String _orderProductSummary(CustomerOrderModel order, L t) {
  if (order.items.isEmpty) {
    return _orderText(
      t,
      en: 'No products in this order',
      ru: 'В заказе нет товаров',
      uz: "Buyurtmada mahsulot yo'q",
    );
  }

  final items = order.items
      .map((item) => '${_orderProductTitle(item, t)} x${item.quantity}')
      .toList(growable: false);
  final visibleItems = items.take(2).toList(growable: false);
  final extraCount = items.length - visibleItems.length;
  if (extraCount <= 0) return visibleItems.join(', ');
  return '${visibleItems.join(', ')} +$extraCount';
}

BranchModel? _findBranch(List<BranchModel> branches, String? id) {
  final branchId = id?.trim();
  if (branchId == null || branchId.isEmpty) return null;
  for (final branch in branches) {
    if (branch.id == branchId) return branch;
  }
  return null;
}

ClientAddress? _findAddress(List<ClientAddress> addresses, String? id) {
  final addressId = id?.trim();
  if (addressId == null || addressId.isEmpty) return null;
  for (final address in addresses) {
    if (address.id == addressId) return address;
  }
  return null;
}

String _formatOrderAddress(ClientAddress address, L t) {
  final primaryParts = <String>[
    if (address.street.trim().isNotEmpty) address.street.trim(),
    if (address.houseNumber?.trim().isNotEmpty == true)
      address.houseNumber!.trim(),
  ];
  final detailParts = <String>[
    if (address.apartmentNumber?.trim().isNotEmpty == true)
      '${t.apartmentLabel} ${address.apartmentNumber!.trim()}',
    if (address.entrance?.trim().isNotEmpty == true)
      '${t.entranceLabel} ${address.entrance!.trim()}',
    if (address.floor?.trim().isNotEmpty == true)
      '${t.floorLabel} ${address.floor!.trim()}',
  ];

  final primary = primaryParts.isEmpty
      ? address.label.trim()
      : primaryParts.join(', ');
  if (detailParts.isEmpty) return primary;
  return '$primary\n${detailParts.join(', ')}';
}

String? _orderDestination(
  CustomerOrderModel order,
  List<BranchModel> branches,
  List<ClientAddress> addresses,
  L t,
) {
  if (order.type == MobileOrderType.pickup) {
    final branch = _findBranch(branches, order.branchId);
    if (branch == null) return order.branchId;

    final address = branch.address?.trim();
    if (address == null || address.isEmpty) return branch.name;
    return '${branch.name}\n$address';
  }

  final address = _findAddress(addresses, order.addressId);
  if (address == null) return order.addressId;
  return _formatOrderAddress(address, t);
}

List<OrderStatusLogModel> _statusEntries(CustomerOrderModel order) {
  if (order.statusLog.isNotEmpty) return order.statusLog;
  return <OrderStatusLogModel>[
    OrderStatusLogModel(
      status: order.status,
      changedAt: order.updatedAt ?? order.createdAt,
    ),
  ];
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.locale,
    required this.branches,
    required this.addresses,
  });

  final CustomerOrderModel order;
  final String locale;
  final List<BranchModel> branches;
  final List<ClientAddress> addresses;

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderDetailsSheet(
          order: order,
          locale: locale,
          branches: branches,
          addresses: addresses,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final colors = _statusColors(order.status);
    final date = _formatOrderDate(order.createdAt, locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _statusSurfaceColors(order.status, isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: surface.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surface.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: surface.accent.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: surface.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: surface.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TypographyText(
                            '#${_shortOrderId(order.id)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (date.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: BaseColors.textGray,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: TypographyText(
                                    date,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BaseColors.textGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OrderStatusChip(
                      label: _statusLabel(order.status, t),
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.fastfood_outlined,
                      size: 17,
                      color: BaseColors.textGray,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: TypographyText(
                        _orderProductSummary(order, t),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0x1A8C8278)),
                const SizedBox(height: 9),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: _OrderMiniBadge(
                        icon: _orderTypeIcon(order.type),
                        label: _orderTypeLabel(order.type, t),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TypographyText(
                      _formatOrderAmount(order.totalAmount),
                      style: const TextStyle(
                        color: BaseColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: BaseColors.textGray,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.label, required this.colors});

  final String label;
  final ({Color bg, Color text}) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: TypographyText(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderMiniBadge extends StatelessWidget {
  const _OrderMiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: BaseColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: TypographyText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BaseColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailsSheet extends StatefulWidget {
  const _OrderDetailsSheet({
    required this.order,
    required this.locale,
    required this.branches,
    required this.addresses,
  });

  final CustomerOrderModel order;
  final String locale;
  final List<BranchModel> branches;
  final List<ClientAddress> addresses;

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  late CustomerOrderModel _order;
  bool _isRetryingPayment = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  bool get _canRetryPayment => _order.paymentRetryAvailable;

  Future<void> _retryPayment() async {
    if (_isRetryingPayment) return;
    final t = L.of(context);

    setState(() => _isRetryingPayment = true);
    final result = await context
        .read<MobileBackendController>()
        .retryOrderPayment(id: _order.id);
    if (!mounted) return;

    setState(() => _isRetryingPayment = false);
    switch (result) {
      case Success(:final data):
        setState(() => _order = data);
        final paymentUrl = data.paymentUrl?.trim();
        if (paymentUrl?.isNotEmpty != true) {
          _showOrderSnack(
            _orderText(
              t,
              en: 'Payment link is not available yet.',
              ru: 'Ссылка на оплату пока недоступна.',
              uz: "To'lov havolasi hali mavjud emas.",
            ),
          );
          return;
        }

        final opened = await ExternalUrlLauncher.open(paymentUrl!);
        if (!mounted) return;
        _showOrderSnack(
          opened
              ? _orderText(
                  t,
                  en: 'Complete payment online.',
                  ru: 'Завершите онлайн-оплату.',
                  uz: "Onlayn to'lovni yakunlang.",
                )
              : _orderText(
                  t,
                  en: 'Payment page could not be opened.',
                  ru: 'Не удалось открыть страницу оплаты.',
                  uz: "To'lov sahifasini ochib bo'lmadi.",
                ),
        );
      case Error(:final failure):
        _showOrderSnack(
          failure.message.isNotEmpty
              ? failure.message
              : _orderText(
                  t,
                  en: 'Could not retry payment.',
                  ru: 'Не удалось повторить оплату.',
                  uz: "To'lovni qayta urinish imkoni bo'lmadi.",
                ),
        );
    }
  }

  void _showOrderSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message));
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = _order;
    final colors = _statusColors(order.status);
    final destination = _orderDestination(
      order,
      widget.branches,
      widget.addresses,
      t,
    );
    final statusEntries = _statusEntries(order);
    final createdAt = _formatOrderDateTime(order.createdAt, widget.locale);
    final scheduledFor = _formatOrderDateTime(
      order.scheduledFor,
      widget.locale,
    );
    final updatedAt = _formatOrderDateTime(order.updatedAt, widget.locale);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          22 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4A4038)
                      : const Color(0xFFE5DAD0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TypographyText(
                        _orderText(
                          t,
                          en: 'Order details',
                          ru: 'Детали заказа',
                          uz: 'Buyurtma tafsilotlari',
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TypographyText(
                        '#${_shortOrderId(order.id)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BaseColors.textGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.track_changes_rounded, color: colors.text),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          _orderText(
                            t,
                            en: 'Current status',
                            ru: 'Текущий статус',
                            uz: 'Joriy holat',
                          ),
                          style: TextStyle(
                            color: colors.text.withValues(alpha: 0.78),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TypographyText(
                          _statusLabel(order.status, t),
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _OrderInfoPill(
              icon: _orderTypeIcon(order.type),
              label: _orderText(
                t,
                en: 'Order type',
                ru: 'Тип заказа',
                uz: 'Buyurtma turi',
              ),
              value: _orderTypeLabel(order.type, t),
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.event_available_rounded,
                label: _orderText(
                  t,
                  en: 'Created',
                  ru: 'Создан',
                  uz: 'Yaratilgan',
                ),
                value: createdAt,
              ),
            ],
            if (scheduledFor.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.schedule_rounded,
                label: _orderText(
                  t,
                  en: 'Scheduled for',
                  ru: 'Запланирован',
                  uz: 'Rejalashtirilgan',
                ),
                value: scheduledFor,
              ),
            ],
            if (updatedAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.update_rounded,
                label: _orderText(
                  t,
                  en: 'Last update',
                  ru: 'Последнее обновление',
                  uz: 'Oxirgi yangilanish',
                ),
                value: updatedAt,
              ),
            ],
            const SizedBox(height: 8),
            _OrderInfoPill(
              icon: Icons.payments_outlined,
              label: _orderText(t, en: 'Payment', ru: 'Оплата', uz: "To'lov"),
              value: _paymentMethodLabel(order.paymentMethod, t),
            ),
            if (order.paymentStatus != null &&
                order.paymentStatus != MobilePaymentStatus.unknown) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: Icons.verified_outlined,
                label: _orderText(
                  t,
                  en: 'Payment status',
                  ru: 'Статус оплаты',
                  uz: "To'lov holati",
                ),
                value: _paymentStatusLabel(order.paymentStatus!, t),
              ),
            ],
            if (_canRetryPayment) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: BaseColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isRetryingPayment
                      ? null
                      : () => unawaited(_retryPayment()),
                  icon: _isRetryingPayment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BaseColors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 19),
                  label: TypographyText(
                    _orderText(
                      t,
                      en: 'Retry payment',
                      ru: 'Повторить оплату',
                      uz: "To'lovni qayta urinish",
                    ),
                    style: const TextStyle(
                      color: BaseColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            if (destination?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _OrderInfoPill(
                icon: order.type == MobileOrderType.delivery
                    ? Icons.location_on_outlined
                    : Icons.storefront_rounded,
                label: order.type == MobileOrderType.delivery
                    ? t.deliveryAddress
                    : t.selectBranch,
                value: destination!.trim(),
              ),
            ],
            const SizedBox(height: 14),
            _OrderDetailSection(
              title: _orderText(
                t,
                en: 'Products',
                ru: 'Товары',
                uz: 'Mahsulotlar',
              ),
              children: order.items.isEmpty
                  ? <Widget>[
                      TypographyText(
                        _orderProductSummary(order, t),
                        style: const TextStyle(color: BaseColors.textGray),
                      ),
                    ]
                  : <Widget>[
                      for (int i = 0; i < order.items.length; i++) ...[
                        _OrderProductDetailLine(item: order.items[i]),
                        if (i < order.items.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0x1A8C8278)),
                          ),
                      ],
                    ],
            ),
            const SizedBox(height: 12),
            _OrderDetailSection(
              title: _orderText(
                t,
                en: 'Status history',
                ru: 'История статусов',
                uz: 'Holatlar tarixi',
              ),
              children: <Widget>[
                for (int i = 0; i < statusEntries.length; i++) ...[
                  _OrderStatusLogLine(
                    entry: statusEntries[i],
                    locale: widget.locale,
                  ),
                  if (i < statusEntries.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
            if (order.promoCode?.trim().isNotEmpty == true ||
                order.comment?.trim().isNotEmpty == true ||
                order.iikoOrderId?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _OrderDetailSection(
                title: _orderText(
                  t,
                  en: 'Additional info',
                  ru: 'Дополнительно',
                  uz: "Qo'shimcha ma'lumot",
                ),
                children: <Widget>[
                  if (order.promoCode?.trim().isNotEmpty == true)
                    _OrderTextDetail(
                      label: t.promoCode,
                      value: order.promoCode!.trim(),
                    ),
                  if (order.comment?.trim().isNotEmpty == true) ...[
                    if (order.promoCode?.trim().isNotEmpty == true)
                      const SizedBox(height: 10),
                    _OrderTextDetail(
                      label: t.commentLabel,
                      value: order.comment!.trim(),
                    ),
                  ],
                  if (order.iikoOrderId?.trim().isNotEmpty == true) ...[
                    if (order.promoCode?.trim().isNotEmpty == true ||
                        order.comment?.trim().isNotEmpty == true)
                      const SizedBox(height: 10),
                    _OrderTextDetail(
                      label: _orderText(
                        t,
                        en: 'Kitchen order',
                        ru: 'Заказ кухни',
                        uz: 'Oshxona buyurtmasi',
                      ),
                      value: order.iikoOrderId!.trim(),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    t.total,
                    style: const TextStyle(
                      color: BaseColors.textGray,
                      fontSize: 15,
                    ),
                  ),
                ),
                TypographyText(
                  _formatOrderAmount(order.totalAmount),
                  style: const TextStyle(
                    color: BaseColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderInfoPill extends StatelessWidget {
  const _OrderInfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  label,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                TypographyText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailSection extends StatelessWidget {
  const _OrderDetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TypographyText(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _OrderProductDetailLine extends StatelessWidget {
  const _OrderProductDetailLine({required this.item});

  final CustomerOrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final amount = item.amount > 0 ? _formatOrderAmount(item.amount) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TypographyText(
            '${item.quantity}x',
            style: const TextStyle(
              color: BaseColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                _orderProductTitle(item, t),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (item.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                TypographyText(
                  item.comment!.trim(),
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (amount != null) ...[
          const SizedBox(width: 8),
          TypographyText(
            amount,
            style: const TextStyle(
              color: BaseColors.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrderStatusLogLine extends StatelessWidget {
  const _OrderStatusLogLine({required this.entry, required this.locale});

  final OrderStatusLogModel entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final colors = _statusColors(entry.status);
    final changedAt = _formatOrderDateTime(entry.changedAt, locale);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.bg, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, color: colors.text, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                _statusLabel(entry.status, t),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (changedAt.isNotEmpty) ...[
                const SizedBox(height: 2),
                TypographyText(
                  changedAt,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
              if (entry.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                TypographyText(
                  entry.comment!.trim(),
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderTextDetail extends StatelessWidget {
  const _OrderTextDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TypographyText(
          label,
          style: const TextStyle(
            color: BaseColors.textGray,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        TypographyText(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TypographyText(
            label,
            style: const TextStyle(color: BaseColors.textGray),
          ),
        ),
        TypographyText(
          value,
          style: const TextStyle(
            color: BaseColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
