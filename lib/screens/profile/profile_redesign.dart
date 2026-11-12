part of '../profile.dart';

class _RedesignedProfile extends StatelessWidget {
  const _RedesignedProfile({
    super.key,
    required this.appVersionFuture,
    required this.onRefresh,
    required this.onSignIn,
    required this.onEditProfile,
    required this.onOpenPoints,
    required this.onOpenOrders,
    required this.onOpenPromotions,
    required this.onOpenAddresses,
    required this.onNotificationsChanged,
    required this.onShare,
    required this.onLogout,
    this.onNotificationsTap,
  });

  final Future<String?> appVersionFuture;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onEditProfile;
  final Future<void> Function() onOpenPoints;
  final Future<void> Function() onOpenOrders;
  final Future<void> Function() onOpenPromotions;
  final Future<void> Function() onOpenAddresses;
  final Future<void> Function(bool enabled) onNotificationsChanged;
  final Future<void> Function() onShare;
  final Future<void> Function() onLogout;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final backend = context
        .select<
          MobileBackendController,
          ({
            ClientProfile? client,
            Failure? failure,
            PushNotificationSettings? pushNotificationSettings,
            bool pushNotificationsUpdating,
            int activePromotionCount,
            int? walletBalance,
            int orderCount,
            int addressCount,
            int notificationUnreadCount,
          })
        >(
          // Counts and the balance, not the lists: refreshed lists with the
          // same counts do not rebuild the profile.
          (controller) => (
            client: controller.client,
            failure: controller.failure,
            pushNotificationSettings: controller.pushNotificationSettings,
            pushNotificationsUpdating: controller.pushNotificationsUpdating,
            activePromotionCount: controller.assignedPromotions
                .where((promotion) => promotion.canBeUsed)
                .length,
            walletBalance: controller.loyaltyWallet?.availableBalance,
            orderCount: controller.orders.length,
            addressCount: controller.addresses.length,
            notificationUnreadCount: controller.notificationUnreadCount,
          ),
        );
    final languageCode = context.select<LocaleController, String>(
      (controller) => controller.locale.languageCode,
    );
    final onNotificationsTap = this.onNotificationsTap;
    final themeController = context.read<ThemeController>();
    final client = backend.client;
    final isAuthorized = client != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final failure = backend.failure is AuthFailure ? null : backend.failure;
    final pushSettings = backend.pushNotificationSettings;
    final notificationsEnabled = pushSettings?.enabled ?? false;
    final notificationsSupported = pushSettings?.supported ?? true;
    final activePromotionCount = backend.activePromotionCount;
    final displayName = client?.fullName.trim().isNotEmpty == true
        ? client!.fullName.trim()
        : (isAuthorized ? t.guest : t.authorization);
    final subtitle = isAuthorized
        ? _formatProfilePhone(client.phoneNumber)
        : t.tapToSignIn;
    final points = backend.walletBalance ?? client?.bonusBalance ?? 0;

    return RefreshIndicator(
      color: BaseColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: const ValueKey<String>('profile-scroll'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          t.profile,
                          style: AppTextStyles.display(
                            size: 26,
                            height: 30 / 26,
                            color: _ProfilePalette.primary(context),
                          ).copyWith(letterSpacing: 0),
                        ),
                      ),
                      if (onNotificationsTap != null) ...<Widget>[
                        const SizedBox(width: 10),
                        NotificationButton(
                          key: const ValueKey<String>(
                            'profile-notifications-button',
                          ),
                          unreadCount: backend.notificationUnreadCount,
                          label: t.notificationInbox,
                          onTap: onNotificationsTap,
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _ProfileIdentityCard(
                    cardKey: const ValueKey<String>('profile-header-row'),
                    displayName: displayName,
                    subtitle: subtitle,
                    isAuthorized: isAuthorized,
                    onTap: isAuthorized ? onEditProfile : onSignIn,
                  ),
                ),
                if (isAuthorized)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _ProfilePointsCard(
                      cardKey: const ValueKey<String>('profile-points-row'),
                      points: points,
                      onTap: onOpenPoints,
                    ),
                  ),
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: AnimatedErrorMessage(
                      failure: failure,
                      compact: true,
                      onRetry: () => unawaited(onRefresh()),
                    ),
                  ),
                if (isAuthorized)
                  _ProfileSection(
                    title: t.profileOrdersSection,
                    bottomSpacing: 20,
                    child: _ProfileGroupedCard(
                      children: <Widget>[
                        _ProfileRow(
                          key: const ValueKey<String>('profile-orders-row'),
                          title: t.orderHistory,
                          trailing: _ProfileCountTrailing(
                            value: t.profileOrderCount(backend.orderCount),
                          ),
                          onTap: onOpenOrders,
                        ),
                        const _ProfileDivider(),
                        _ProfileRow(
                          key: const ValueKey<String>('profile-promos-row'),
                          title: t.myPromotions,
                          trailing: _ProfileBadge(count: activePromotionCount),
                          onTap: onOpenPromotions,
                        ),
                        const _ProfileDivider(),
                        _ProfileRow(
                          key: const ValueKey<String>('profile-addresses-row'),
                          title: t.myAddresses,
                          trailing: _ProfileCountTrailing(
                            value: t.profileAddressCount(backend.addressCount),
                          ),
                          onTap: onOpenAddresses,
                        ),
                      ],
                    ),
                  ),
                _ProfileSection(
                  title: t.settings.toUpperCase(),
                  bottomSpacing: 20,
                  child: _ProfileGroupedCard(
                    children: <Widget>[
                      _ProfileRow(
                        key: const ValueKey<String>('profile-language-row'),
                        title: t.language,
                        trailing: _ProfileCountTrailing(
                          value: _profileLanguageName(languageCode),
                        ),
                        onTap: () => _showProfileLanguageSheet(
                          context,
                          context.read<LocaleController>(),
                        ),
                      ),
                      const _ProfileDivider(),
                      _ProfileDetailRow(
                        key: const ValueKey<String>('profile-theme-row'),
                        title: t.appearance,
                        subtitle: t.chooseAppColorMode,
                        trailing: _ProfileThemePill(isDark: isDark),
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await themeController.setTheme(
                            isDark ? ThemeMode.light : ThemeMode.dark,
                          );
                        },
                      ),
                      const _ProfileDivider(),
                      _ProfileDetailRow(
                        key: const ValueKey<String>(
                          'profile-notifications-row',
                        ),
                        title: t.notifications,
                        subtitle: t.profileNotificationsSubtitle,
                        trailing: _ProfileSwitch(
                          value: notificationsEnabled,
                          loading: backend.pushNotificationsUpdating,
                          enabled:
                              pushSettings != null &&
                              notificationsSupported &&
                              !backend.pushNotificationsUpdating,
                          onChanged: (value) =>
                              unawaited(onNotificationsChanged(value)),
                        ),
                        onTap:
                            pushSettings != null &&
                                notificationsSupported &&
                                !backend.pushNotificationsUpdating
                            ? () =>
                                  onNotificationsChanged(!notificationsEnabled)
                            : null,
                      ),
                    ],
                  ),
                ),
                _ProfileSection(
                  title: t.actions.toUpperCase(),
                  bottomSpacing: 14,
                  child: _ProfileGroupedCard(
                    children: <Widget>[
                      _ProfileRow(
                        key: const ValueKey<String>('profile-share-row'),
                        title: t.shareApp,
                        onTap: onShare,
                      ),
                      if (isAuthorized) ...<Widget>[
                        const _ProfileDivider(),
                        _ProfileRow(
                          key: const ValueKey<String>('profile-logout-row'),
                          title: t.logout,
                          danger: true,
                          showChevron: false,
                          onTap: onLogout,
                        ),
                      ],
                    ],
                  ),
                ),
                _ProfileVersion(
                  key: const ValueKey<String>('profile-version-label'),
                  future: appVersionFuture,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePalette {
  const _ProfilePalette._();

  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color ground(BuildContext context) => AppDesignTokens.ground(context);

  static Color surface(BuildContext context) =>
      AppDesignTokens.surface(context);

  static Color primary(BuildContext context) =>
      AppDesignTokens.primaryText(context);

  static Color secondary(BuildContext context) => dark(context)
      ? const Color(0xFFAAA39A)
      : AppDesignTokens.ink.withValues(alpha: 0.60);

  static Color tertiary(BuildContext context) => dark(context)
      ? const Color(0xFF8A837B)
      : AppDesignTokens.ink.withValues(alpha: 0.45);

  static Color chevron(BuildContext context) => dark(context)
      ? Colors.white.withValues(alpha: 0.45)
      : AppDesignTokens.ink.withValues(alpha: 0.45);

  static Color actionSoft(BuildContext context) => dark(context)
      ? AppDesignTokens.action.withValues(alpha: 0.18)
      : AppDesignTokens.actionSoft;

  static Color goldWash(BuildContext context) => dark(context)
      ? AppDesignTokens.gold.withValues(alpha: 0.13)
      : AppDesignTokens.goldWash;

  static Color goldInk(BuildContext context) =>
      AppDesignTokens.goldText(context);

  static Color themePill(BuildContext context) => dark(context)
      ? Colors.white.withValues(alpha: 0.06)
      : AppDesignTokens.ink.withValues(alpha: 0.06);

  static Color switchOff(BuildContext context) => dark(context)
      ? Colors.white.withValues(alpha: 0.16)
      : AppDesignTokens.ink.withValues(alpha: 0.15);

  static Color danger(BuildContext context) =>
      dark(context) ? const Color(0xFFFF8A80) : AppDesignTokens.danger;
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.cardKey,
    required this.displayName,
    required this.subtitle,
    required this.isAuthorized,
    required this.onTap,
  });

  final Key cardKey;
  final String displayName;
  final String subtitle;
  final bool isAuthorized;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().substring(0, 1).toUpperCase();

    return _ProfileCardShell(
      boxKey: cardKey,
      child: Semantics(
        button: true,
        label: isAuthorized
            ? L.of(context).editProfile
            : L.of(context).authorization,
        child: InkWell(
          onTap: () => unawaited(onTap()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _ProfilePalette.actionSoft(context),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: AppTextStyles.display(
                      size: 20,
                      height: 23 / 20,
                      color: BaseColors.primary,
                    ).copyWith(letterSpacing: 0),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.ui(
                          size: 17,
                          height: 22 / 17,
                          weight: FontWeight.w600,
                          color: _ProfilePalette.primary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: isAuthorized ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.ui(
                          size: 13.5,
                          height: 19 / 13.5,
                          color: _ProfilePalette.secondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ProfileChevron(color: _ProfilePalette.chevron(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePointsCard extends StatelessWidget {
  const _ProfilePointsCard({
    required this.cardKey,
    required this.points,
    required this.onTap,
  });

  final Key cardKey;
  final int points;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final ink = _ProfilePalette.goldInk(context);
    return Semantics(
      key: cardKey,
      button: true,
      label:
          '${t.profilePointsLabel}, ${t.loyaltyBalancePoints(_formatProfileInteger(points))}',
      child: Material(
        color: _ProfilePalette.goldWash(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => unawaited(onTap()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        t.profilePointsLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.ui(
                          size: 11.5,
                          height: 15 / 11.5,
                          weight: FontWeight.w600,
                          color: ink.withValues(alpha: 0.70),
                        ).copyWith(letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.loyaltyBalancePoints(_formatProfileInteger(points)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.display(
                          size: 21,
                          height: 24 / 21,
                          color: ink,
                        ).copyWith(letterSpacing: 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  t.viewPoints,
                  maxLines: 1,
                  style: AppTextStyles.ui(
                    size: 13.5,
                    height: 17 / 13.5,
                    weight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatProfilePhone(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 12 && digits.startsWith('998')) {
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
        '${digits.substring(5, 8)} ${digits.substring(8, 10)} '
        '${digits.substring(10, 12)}';
  }
  return value.trim();
}

String _formatProfileInteger(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(' ');
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}
