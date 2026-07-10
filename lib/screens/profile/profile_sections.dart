part of 'package:enjoy_lavash_mobile/screens/profile.dart';

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.isDark,
    required this.isAuthorized,
    required this.displayName,
    required this.subtitle,
    required this.onSignIn,
  });

  final bool isDark;
  final bool isAuthorized;
  final String displayName;
  final String subtitle;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: GestureDetector(
        onTap: isAuthorized ? null : onSignIn,
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
                    colors: <Color>[Color(0xFFFFC107), BaseColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Icon(
                    isAuthorized ? Icons.person_rounded : Icons.login_rounded,
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
                      subtitle,
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
    );
  }
}

class _ProfileSettingsSection extends StatelessWidget {
  const _ProfileSettingsSection({
    required this.isDark,
    required this.locale,
    required this.notificationsSubtitle,
    required this.notificationsEnabled,
    required this.notificationsLoading,
    required this.notificationsToggleEnabled,
    required this.onNotificationsChanged,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  final bool isDark;
  final Locale locale;
  final String notificationsSubtitle;
  final bool notificationsEnabled;
  final bool notificationsLoading;
  final bool notificationsToggleEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return _SectionCard(
      isDark: isDark,
      title: t.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _NotificationSwitchTile(
            isDark: isDark,
            title: t.notifications,
            subtitle: notificationsSubtitle,
            value: notificationsEnabled,
            loading: notificationsLoading,
            enabled: notificationsToggleEnabled,
            onChanged: onNotificationsChanged,
          ),
          const _SettingsDivider(),
          _SettingsHeader(
            icon: Icons.palette_outlined,
            title: t.appearance,
            subtitle: t.chooseAppColorMode,
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
                  onTap: () => onThemeChanged(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PreferenceChip(
                  label: t.darkTheme,
                  icon: Icons.dark_mode_rounded,
                  isActive: isDark,
                  isDark: isDark,
                  onTap: () => onThemeChanged(ThemeMode.dark),
                ),
              ),
            ],
          ),
          const _SettingsDivider(),
          _SettingsHeader(
            icon: Icons.translate_rounded,
            title: t.language,
            subtitle: t.languageSubtitle,
          ),
          const SizedBox(height: 12),
          _LanguageSelector(
            value: locale,
            isDark: isDark,
            onChanged: onLocaleChanged,
          ),
        ],
      ),
    );
  }
}

class _ProfilePersonalInfoSection extends StatelessWidget {
  const _ProfilePersonalInfoSection({
    required this.isDark,
    required this.phoneNumber,
    this.addressText,
  });

  final bool isDark;
  final String phoneNumber;
  final String? addressText;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return FadeSlideIn(
      child: _SectionCard(
        isDark: isDark,
        title: t.personalInfo,
        child: Column(
          children: <Widget>[
            _InfoRow(
              icon: Icons.phone_outlined,
              title: t.phoneNumber,
              value: phoneNumber,
            ),
            if (addressText != null) ...[
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.location_on_outlined,
                title: t.address,
                value: addressText!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersSection extends StatelessWidget {
  const _RecentOrdersSection({
    required this.isDark,
    required this.orders,
    required this.locale,
    required this.branches,
    required this.addresses,
    required this.hasMoreOrders,
    required this.onSeeAllOrders,
  });

  final bool isDark;
  final List<CustomerOrderModel> orders;
  final String locale;
  final List<BranchModel> branches;
  final List<ClientAddress> addresses;
  final bool hasMoreOrders;
  final VoidCallback onSeeAllOrders;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return FadeSlideIn(
      child: _SectionCard(
        isDark: isDark,
        title: t.orderHistory,
        padding: const EdgeInsets.all(14),
        titleBottomSpacing: 12,
        child: Column(
          children: <Widget>[
            for (int i = 0; i < orders.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _OrderRow(
                order: orders[i],
                locale: locale,
                branches: branches,
                addresses: addresses,
              ),
            ],
            if (hasMoreOrders) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BaseColors.primary,
                    side: const BorderSide(color: BaseColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onSeeAllOrders,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: TypographyText(t.seeAllOrders),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CashbackSection extends StatelessWidget {
  const _CashbackSection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return _SectionCard(
      isDark: isDark,
      title: t.cashbackSystem,
      child: Column(
        children: <Widget>[
          _StatLine(label: t.perOrder, value: t.perOrderValue),
          const SizedBox(height: 10),
          _StatLine(label: t.onePointEquals, value: t.onePointValue),
          const SizedBox(height: 10),
          _StatLine(label: t.canSpend, value: t.canSpendValue),
        ],
      ),
    );
  }
}

class _ProfileActionsSection extends StatelessWidget {
  const _ProfileActionsSection({
    required this.isDark,
    required this.isAuthorized,
    required this.appVersionFuture,
    required this.onShare,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final bool isDark;
  final bool isAuthorized;
  final Future<String?> appVersionFuture;
  final VoidCallback onShare;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return _SectionCard(
      isDark: isDark,
      title: t.actions,
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
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined),
              label: TypographyText(t.shareApp),
            ),
          ),
          if (isAuthorized) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: BaseColors.danger,
                  side: const BorderSide(color: BaseColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: onLogout,
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: onDeleteAccount,
                icon: const Icon(Icons.delete_forever_outlined, size: 20),
                label: TypographyText(
                  t.deleteAccount,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const _SettingsDivider(),
          _AppVersionRow(future: appVersionFuture, isDark: isDark),
        ],
      ),
    );
  }
}
