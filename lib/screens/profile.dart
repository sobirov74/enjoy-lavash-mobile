import 'dart:async';

import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/confirm_dialog.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/app_share_service.dart';
import 'package:enjoy_lavash_mobile/core/services/external_url_launcher.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/screens/assigned_promotions_screen.dart';
import 'package:enjoy_lavash_mobile/screens/notifications_screen.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';

part 'profile/delete_account_sheet.dart';
part 'profile/profile_sections.dart';
part 'profile/all_orders_screen.dart';
part 'profile/settings_widgets.dart';
part 'profile/profile_cards.dart';
part 'profile/order_helpers.dart';
part 'profile/order_row.dart';
part 'profile/order_details_sheet.dart';
part 'profile/order_detail_widgets.dart';

Future<void> showProfileOrderDetailsSheet({
  required BuildContext context,
  required CustomerOrderModel order,
  required String locale,
  required List<BranchModel> branches,
  required List<ClientAddress> addresses,
}) {
  return showModalBottomSheet<void>(
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

class Profile extends StatefulWidget {
  const Profile({super.key, this.onRefresh, this.onPromoSelected});

  final Future<void> Function()? onRefresh;
  final ValueChanged<String>? onPromoSelected;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late final Future<String?> _appVersionFuture;
  bool _marketingConsentUpdating = false;

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
    await AppShareService.share(t);
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

  Future<void> _openNotifications(BuildContext context) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const NotificationsScreen()),
    );
    if (code != null) {
      widget.onPromoSelected?.call(code);
    }
  }

  Future<void> _openAssignedPromotions(BuildContext context) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const AssignedPromotionsScreen(),
      ),
    );
    if (code != null) {
      widget.onPromoSelected?.call(code);
    }
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
              ? t.allowNotificationsInSettings
              : t.notificationPermissionDenied;
          ScaffoldMessenger.of(context).showSnackBar(appSnackBar(message));
        }
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(
            failure.message.isNotEmpty
                ? failure.message
                : t.notificationUpdateFailed,
          ),
        );
    }
  }

  Future<void> _setMarketingConsent(BuildContext context, bool enabled) async {
    if (_marketingConsentUpdating) return;
    final messenger = ScaffoldMessenger.of(context);
    final fallbackMessage = L.of(context).marketingUpdateFailed;
    setState(() => _marketingConsentUpdating = true);
    final result = await context.read<MobileBackendController>().updateProfile(
      ClientProfileUpdate(marketingConsent: enabled),
    );
    if (!mounted) return;
    setState(() => _marketingConsentUpdating = false);
    if (result case Error(:final failure)) {
      messenger.showSnackBar(
        appSnackBar(
          failure.message.trim().isNotEmpty ? failure.message : fallbackMessage,
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
    final backendFailure = mobileBackend.failure is AuthFailure
        ? null
        : mobileBackend.failure;
    final pushSettings = mobileBackend.pushNotificationSettings;
    final notificationsLoading = mobileBackend.pushNotificationsUpdating;
    final notificationsSupported = pushSettings?.supported ?? true;
    final notificationsEnabled = pushSettings?.enabled ?? false;
    final primaryAddressText = mobileBackend.addresses.isEmpty
        ? null
        : _formatAddress(mobileBackend.addresses.first);
    final activePromotionCount = mobileBackend.assignedPromotions
        .where((promotion) => promotion.canBeUsed)
        .length;

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
                  _ProfileHeaderCard(
                    isDark: isDark,
                    isAuthorized: isAuthorized,
                    displayName: displayName,
                    subtitle: profileSubtitle,
                    bonusBalance: client?.bonusBalance,
                    onSignIn: () => unawaited(_showAuthorizationModal(context)),
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

                  if (isAuthorized) ...[
                    _ProfileBenefitsSection(
                      isDark: isDark,
                      unreadCount: mobileBackend.notificationUnreadCount,
                      activePromotionCount: activePromotionCount,
                      onNotificationsTap: () =>
                          unawaited(_openNotifications(context)),
                      onPromotionsTap: () =>
                          unawaited(_openAssignedPromotions(context)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _ProfileSettingsSection(
                    isDark: isDark,
                    locale: localeController.locale,
                    notificationsSubtitle: _notificationSubtitle(
                      t,
                      isLoading: pushSettings == null,
                      supported: notificationsSupported,
                      enabled: notificationsEnabled,
                      permissionPermanentlyDenied:
                          pushSettings?.permissionPermanentlyDenied ?? false,
                    ),
                    notificationsEnabled: notificationsEnabled,
                    notificationsLoading: notificationsLoading,
                    notificationsToggleEnabled:
                        pushSettings != null &&
                        notificationsSupported &&
                        !mobileBackend.pushNotificationsUpdating,
                    onNotificationsChanged: (value) =>
                        unawaited(_setPushNotifications(context, value)),
                    isAuthorized: isAuthorized,
                    marketingConsent: client?.marketingConsent ?? false,
                    marketingConsentLoading: _marketingConsentUpdating,
                    onMarketingConsentChanged: (value) =>
                        unawaited(_setMarketingConsent(context, value)),
                    onThemeChanged: (mode) =>
                        unawaited(themeController.setTheme(mode)),
                    onLocaleChanged: (locale) {
                      if (localeController.locale == locale) return;
                      HapticFeedback.selectionClick();
                      unawaited(localeController.setLocale(locale));
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isAuthorized)
                    _ProfilePersonalInfoSection(
                      isDark: isDark,
                      phoneNumber: phoneNumber,
                      addressText: primaryAddressText,
                    ),
                  if (isAuthorized) const SizedBox(height: 16),

                  if (mobileBackend.orders.isNotEmpty) ...[
                    _RecentOrdersSection(
                      isDark: isDark,
                      orders: recentOrders,
                      locale: localeController.locale.languageCode,
                      branches: mobileBackend.branches,
                      addresses: mobileBackend.addresses,
                      hasMoreOrders: hasMoreOrders,
                      onSeeAllOrders: () => _openAllOrders(context),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _CashbackSection(isDark: isDark),
                  const SizedBox(height: 16),

                  _ProfileActionsSection(
                    isDark: isDark,
                    isAuthorized: isAuthorized,
                    appVersionFuture: _appVersionFuture,
                    onShare: () => unawaited(_shareApp(t)),
                    onLogout: () => _confirmLogout(context, t),
                    onDeleteAccount: () =>
                        unawaited(_showDeleteAccountSheet(context)),
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
