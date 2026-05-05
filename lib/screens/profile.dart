import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';
import 'package:enjoy_lavash_mobile/widgets/button.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  static const int _loyaltyPoints = 1250;

  Future<void> _shareApp(L t) async {
    await SharePlus.instance.share(
      ShareParams(text: t.shareAppText),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeController = context.read<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final t = L.of(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
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
                _SurfaceCard(
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
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        child: const TypographyText(
                          '👤',
                          style: TextStyle(fontSize: 34),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TypographyText(
                              t.guest,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const TypographyText(
                              '+998 90 123 45 67',
                              style: TextStyle(
                                color: BaseColors.textGray,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 28),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- Theme toggle
                _SurfaceCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: MainButton(
                          title: TypographyText(
                            t.lightTheme,
                            style: TextStyle(color: context.colors.text),
                          ),
                          icon: Icon(
                            Icons.light_mode_rounded,
                            color: context.colors.text,
                          ),
                          onPressed: () =>
                              themeController.setTheme(ThemeMode.light),
                          elevation: 0,
                          backgroundColor: !isDark
                              ? BaseColors.primary
                              : BaseColors.black600,
                          foregroundColor: !isDark
                              ? Colors.white
                              : const Color(0xFF14110F),
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MainButton(
                          title: TypographyText(
                            t.darkTheme,
                            style: TextStyle(color: context.colors.text),
                          ),
                          icon: Icon(
                            Icons.dark_mode_rounded,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF14110F),
                          ),
                          onPressed: () =>
                              themeController.setTheme(ThemeMode.dark),
                          elevation: 0,
                          backgroundColor: isDark
                              ? BaseColors.primary
                              : const Color(0xFFF3F0EB),
                          foregroundColor: isDark
                              ? Colors.white
                              : const Color(0xFF14110F),
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- Language selector
                _SurfaceCard(
                  isDark: isDark,
                  padding: const EdgeInsets.all(8),
                  child: Row(
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
                            isActive: localeController.locale == entry.locale,
                            isDark: isDark,
                            onTap: () =>
                                localeController.setLocale(entry.locale),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- Loyalty card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[BaseColors.primary, Color(0xFFFF7043)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TypographyText(
                        t.loyaltyCard,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TypographyText(
                        t.accumulatedPoints,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 18),
                      const TypographyText(
                        '1 250',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 180,
                              color: Colors.grey.shade900,
                            ),
                            const SizedBox(height: 8),
                            TypographyText(
                              'ENJOY-LAVASH-$_loyaltyPoints',
                              style: const TextStyle(
                                letterSpacing: 2.4,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TypographyText(
                        t.showCodeForPoints,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- Personal info
                _SectionCard(
                  isDark: isDark,
                  title: t.personalInfo,
                  child: Column(
                    children: <Widget>[
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        title: t.email,
                        value: 'guest@enjoylavash.uz',
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        title: t.address,
                        value: 'г. Ташкент, ул. Навои 25',
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        title: t.customerId,
                        value: 'EL-12345',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- Order history
                _SectionCard(
                  isDark: isDark,
                  title: t.orderHistory,
                  child: Column(
                    children: <Widget>[
                      _OrderRow(
                        id: 'ORD-2026-001',
                        date: '10 апреля 2026',
                        total: '80 000 so\'m',
                        status: t.completed,
                        items:
                            '🌯 Лаваш куриный с сыром × 2, 🥤 Pepsi × 1',
                      ),
                      const SizedBox(height: 12),
                      _OrderRow(
                        id: 'ORD-2026-002',
                        date: '8 апреля 2026',
                        total: '47 000 so\'m',
                        status: t.completed,
                        items:
                            '🍔 Бургер классик × 1, 🍟 Картошка фри × 1',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- Cashback system
                _SectionCard(
                  isDark: isDark,
                  title: t.cashbackSystem,
                  child: Column(
                    children: <Widget>[
                      _StatLine(
                          label: t.perOrder, value: t.perOrderValue),
                      const SizedBox(height: 10),
                      _StatLine(
                          label: t.onePointEquals,
                          value: t.onePointValue),
                      const SizedBox(height: 10),
                      _StatLine(
                          label: t.canSpend, value: t.canSpendValue),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- Share button
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
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
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
      child: Container(
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
  });

  final bool isDark;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TypographyText(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
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

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
    required this.items,
  });

  final String id;
  final String date;
  final String total;
  final String status;
  final String items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2522)
            : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TypographyText(
                  id,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TypographyText(
                  status,
                  style: const TextStyle(
                    color: BaseColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TypographyText(
            date,
            style: const TextStyle(color: BaseColors.textGray, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TypographyText(
            items,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 10),
          TypographyText(
            total,
            style: const TextStyle(
              color: BaseColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
