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

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final backend = context.watch<MobileBackendController>();
    final localeController = context.watch<LocaleController>();
    final themeController = context.read<ThemeController>();
    final client = backend.client;
    final isAuthorized = client != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final failure = backend.failure is AuthFailure ? null : backend.failure;
    final pushSettings = backend.pushNotificationSettings;
    final notificationsEnabled = pushSettings?.enabled ?? false;
    final notificationsSupported = pushSettings?.supported ?? true;
    final activePromotionCount = backend.assignedPromotions
        .where((promotion) => promotion.canBeUsed)
        .length;
    final displayName = client?.fullName.trim().isNotEmpty == true
        ? client!.fullName.trim()
        : (isAuthorized ? t.guest : t.authorization);
    final subtitle = isAuthorized
        ? _formatProfilePhone(client.phoneNumber)
        : t.tapToSignIn;
    final points =
        backend.loyaltyWallet?.availableBalance ?? client?.bonusBalance ?? 0;

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
                  child: Text(
                    t.profile,
                    style: AppTextStyles.display(
                      size: 26,
                      height: 30 / 26,
                      color: _ProfilePalette.primary(context),
                    ).copyWith(letterSpacing: 0),
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
                            value: t.profileOrderCount(backend.orders.length),
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
                            value: t.profileAddressCount(
                              backend.addresses.length,
                            ),
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
                          value: _profileLanguageName(
                            localeController.locale.languageCode,
                          ),
                        ),
                        onTap: () => _showProfileLanguageSheet(
                          context,
                          localeController,
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.child,
    required this.bottomSpacing,
  });

  final String title;
  final Widget child;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.ui(
              size: 11.5,
              height: 15 / 11.5,
              weight: FontWeight.w600,
              color: _ProfilePalette.tertiary(context),
            ).copyWith(letterSpacing: 0.3),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomSpacing),
          child: child,
        ),
      ],
    );
  }
}

class _ProfileGroupedCard extends StatelessWidget {
  const _ProfileGroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _ProfileCardShell(child: Column(children: children));
  }
}

class _ProfileCardShell extends StatelessWidget {
  const _ProfileCardShell({this.boxKey, required this.child});

  final Key? boxKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: boxKey,
      decoration: BoxDecoration(
        color: _ProfilePalette.surface(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        boxShadow: AppDesignTokens.cardShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    super.key,
    required this.title,
    required this.onTap,
    this.trailing,
    this.showChevron = true,
    this.danger = false,
  });

  final String title;
  final Future<void> Function()? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: title,
      child: InkWell(
        onTap: onTap == null ? null : () => unawaited(onTap!()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ui(
                    size: 15,
                    height: 20 / 15,
                    weight: FontWeight.w600,
                    color: danger
                        ? _ProfilePalette.danger(context)
                        : _ProfilePalette.primary(context),
                  ),
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 12),
                trailing!,
              ],
              if (showChevron) ...<Widget>[
                const SizedBox(width: 10),
                _ProfileChevron(color: _ProfilePalette.chevron(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title, $subtitle',
      child: InkWell(
        onTap: onTap == null ? null : () => unawaited(onTap!()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ui(
                        size: 15,
                        height: 20 / 15,
                        weight: FontWeight.w600,
                        color: _ProfilePalette.primary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ui(
                        size: 11.5,
                        height: 15 / 11.5,
                        color: _ProfilePalette.tertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCountTrailing extends StatelessWidget {
  const _ProfileCountTrailing({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      style: AppTextStyles.ui(
        size: 14.5,
        height: 19 / 14.5,
        weight: FontWeight.w600,
        color: _ProfilePalette.secondary(context),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: BaseColors.primary,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.ui(
          size: 11,
          height: 14 / 11,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ProfileThemePill extends StatelessWidget {
  const _ProfileThemePill({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: _ProfilePalette.themePill(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 16,
            color: _ProfilePalette.primary(context),
          ),
          const SizedBox(width: 7),
          Text(
            isDark ? t.darkTheme : t.lightTheme,
            style: AppTextStyles.ui(
              size: 14.5,
              height: 19 / 14.5,
              weight: FontWeight.w600,
              color: _ProfilePalette.primary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSwitch extends StatelessWidget {
  const _ProfileSwitch({
    required this.value,
    required this.enabled,
    required this.loading,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: L.of(context).notifications,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged(!value) : null,
        child: AnimatedContainer(
          duration: AppMotion.state,
          curve: AppMotion.enter,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value
                ? BaseColors.primary
                : _ProfilePalette.switchOff(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
          ),
          child: AnimatedAlign(
            duration: AppMotion.state,
            curve: AppMotion.enter,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: BaseColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: AppDesignTokens.hairline(context)),
      ),
    );
  }
}

class _ProfileChevron extends StatelessWidget {
  const _ProfileChevron({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.chevron_right_rounded, size: 18, color: color);
  }
}

class _ProfileVersion extends StatelessWidget {
  const _ProfileVersion({super.key, required this.future});

  final Future<String?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        final version = snapshot.data;
        return Text(
          version?.isNotEmpty == true
              ? '${L.of(context).appVersion} $version'
              : L.of(context).appVersion,
          textAlign: TextAlign.center,
          style: AppTextStyles.ui(
            size: 11.5,
            height: 15 / 11.5,
            color: _ProfilePalette.tertiary(context),
          ),
        );
      },
    );
  }
}

Future<void> _showProfileLanguageSheet(
  BuildContext context,
  LocaleController controller,
) {
  final t = L.of(context);
  return showAppModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        decoration: BoxDecoration(
          color: _ProfilePalette.surface(sheetContext),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDesignTokens.radiusSheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppBottomSheetDragHandle(),
            const SizedBox(height: 8),
            Text(
              t.language,
              style: AppTextStyles.display(
                size: 21,
                height: 24 / 21,
                color: _ProfilePalette.primary(sheetContext),
              ).copyWith(letterSpacing: 0),
            ),
            const SizedBox(height: 14),
            for (final locale in LocaleController.supportedLocales)
              _ProfileLanguageOption(
                locale: locale,
                selected: controller.locale == locale,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await controller.setLocale(locale);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      );
    },
  );
}

class _ProfileLanguageOption extends StatelessWidget {
  const _ProfileLanguageOption({
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final Locale locale;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusInput),
        onTap: () => unawaited(onTap()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _profileLanguageName(locale.languageCode),
                  style: AppTextStyles.ui(
                    size: 15,
                    height: 20 / 15,
                    weight: FontWeight.w600,
                    color: _ProfilePalette.primary(context),
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: BaseColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _profileLanguageName(String code) => switch (code) {
  'ru' => 'Русский',
  'en' => 'English',
  _ => "O'zbekcha",
};

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
