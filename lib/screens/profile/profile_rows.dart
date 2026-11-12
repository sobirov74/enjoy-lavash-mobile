part of 'package:enjoy_lavash_mobile/screens/profile.dart';

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
