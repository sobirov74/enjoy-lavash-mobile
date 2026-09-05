import 'dart:async';

import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
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
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/screens/address_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/assigned_promotions_screen.dart';
import 'package:enjoy_lavash_mobile/screens/loyalty_wallet_screen.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';

part 'profile/delete_account_sheet.dart';
part 'profile/profile_sections.dart';
part 'profile/all_orders_screen.dart';
part 'profile/settings_widgets.dart';
part 'profile/profile_cards.dart';
part 'profile/order_helpers.dart';
part 'profile/order_row.dart';
part 'profile/order_details_sheet.dart';
part 'profile/order_detail_widgets.dart';
part 'profile/profile_redesign.dart';
part 'profile/profile_edit_screen.dart';
part 'profile/saved_addresses_screen.dart';

Future<void> showProfileOrderDetailsSheet({
  required BuildContext context,
  required CustomerOrderModel order,
  required String locale,
  required List<BranchModel> branches,
  required List<ClientAddress> addresses,
}) {
  return showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    showDragHandle: false,
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

Future<void> showAllOrdersScreen(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const _AllOrdersScreen()));
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
    return showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      showDragHandle: false,
      builder: (_) => const _DeleteAccountSheet(),
    );
  }

  Future<void> _showAuthorizationModal(BuildContext context) async {
    final backend = context.read<MobileBackendController>();
    await showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
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
    if (context.mounted && backend.isAuthenticated) {
      await backend.refreshCustomerData();
    }
  }

  void _openAllOrders(BuildContext context) {
    unawaited(showAllOrdersScreen(context));
  }

  Future<void> _openLoyaltyWallet(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const LoyaltyWalletScreen()),
    );
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

  Future<void> _openProfileEditor(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileEditScreen(
          onDeleteAccount: () => _showDeleteAccountSheet(context),
        ),
      ),
    );
  }

  Future<void> _openSavedAddresses(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const _SavedAddressesScreen()),
    );
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

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return _RedesignedProfile(
      key: const ValueKey<String>('profile-screen'),
      appVersionFuture: _appVersionFuture,
      onRefresh:
          widget.onRefresh ??
          context.read<MobileBackendController>().refreshCustomerData,
      onSignIn: () => _showAuthorizationModal(context),
      onEditProfile: () => _openProfileEditor(context),
      onOpenPoints: () => _openLoyaltyWallet(context),
      onOpenOrders: () async => _openAllOrders(context),
      onOpenPromotions: () => _openAssignedPromotions(context),
      onOpenAddresses: () => _openSavedAddresses(context),
      onNotificationsChanged: (enabled) =>
          _setPushNotifications(context, enabled),
      onShare: () => _shareApp(t),
      onLogout: () async => _confirmLogout(context, t),
    );
  }
}
