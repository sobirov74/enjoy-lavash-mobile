// ignore_for_file: unused_element, unused_element_parameter

part of 'package:enjoy_lavash_mobile/screens/profile.dart';

// ---------------------------------------------------------------------------
// Language segmented control
// ---------------------------------------------------------------------------

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final Locale value;
  final bool isDark;
  final ValueChanged<Locale> onChanged;

  static const List<({Locale locale, String label})> _options = [
    (locale: Locale('uz'), label: "O'zbekcha"),
    (locale: Locale('ru'), label: 'Русский'),
    (locale: Locale('en'), label: 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _options.indexWhere((entry) => entry.locale == value);
    final activeIndex = selectedIndex == -1 ? 0 : selectedIndex;
    final backgroundColor = isDark
        ? const Color(0xFF201C19)
        : const Color(0xFFF3F0EB);

    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const padding = 4.0;
          const gap = 4.0;
          final optionCount = _options.length;
          final itemWidth =
              (constraints.maxWidth - padding * 2 - gap * (optionCount - 1)) /
              optionCount;
          final indicatorLeft = padding + activeIndex * (itemWidth + gap);

          return DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: <Widget>[
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  top: padding,
                  bottom: padding,
                  width: itemWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BaseColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: BaseColors.primary.withValues(alpha: 0.24),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(padding),
                  child: Row(
                    children: <Widget>[
                      for (var i = 0; i < _options.length; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        Expanded(
                          child: _LanguageSegmentButton(
                            label: _options[i].label,
                            selected: i == activeIndex,
                            isDark: isDark,
                            onTap: () => onChanged(_options[i].locale),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageSegmentButton extends StatefulWidget {
  const _LanguageSegmentButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_LanguageSegmentButton> createState() => _LanguageSegmentButtonState();
}

class _LanguageSegmentButtonState extends State<_LanguageSegmentButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.selected
        ? Colors.white
        : (widget.isDark ? Colors.white : const Color(0xFF14110F));

    return Semantics(
      button: true,
      selected: widget.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.selected ? null : (_) => _setPressed(true),
        onTapCancel: widget.selected ? null : () => _setPressed(false),
        onTapUp: widget.selected ? null : (_) => _setPressed(false),
        onTap: widget.selected ? null : widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.97 : 1,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontFamily: 'Circe-Bold',
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  final bool isDark;
  final IconData icon;
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
            t.appVersion,
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
