import 'dart:async';

import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/external_url_launcher.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({
    super.key,
    required this.repository,
    required this.languageCode,
    required this.child,
  });

  final MobileBackendRepository repository;
  final String languageCode;
  final Widget child;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  late Future<AppVersionPolicyModel?> _policyFuture;
  bool _dismissed = false;
  bool _openingStore = false;
  bool _hasCompletedPolicyCheck = false;

  @override
  void initState() {
    super.initState();
    _policyFuture = _loadTrackedPolicy();
  }

  @override
  void didUpdateWidget(covariant AppVersionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languageCode != widget.languageCode && !_dismissed) {
      _policyFuture = _loadTrackedPolicy();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return widget.child;

    return FutureBuilder<AppVersionPolicyModel?>(
      future: _policyFuture,
      builder: (context, snapshot) {
        final policy = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done ||
            policy == null) {
          if (snapshot.connectionState == ConnectionState.done) {
            return widget.child;
          }
          if (_hasCompletedPolicyCheck) {
            return widget.child;
          }
          return const _VersionSplash();
        }

        return PopScope(
          canPop: false,
          child: _VersionPromptStage(
            policy: policy,
            languageCode: widget.languageCode,
            openingStore: _openingStore,
            onUpdate: () => unawaited(_openStore(policy)),
            onLater: policy.forceUpdate
                ? null
                : () {
                    setState(() => _dismissed = true);
                  },
          ),
        );
      },
    );
  }

  Future<AppVersionPolicyModel?> _loadTrackedPolicy() {
    return _loadPolicy().whenComplete(() {
      if (!mounted || _hasCompletedPolicyCheck) return;
      _hasCompletedPolicyCheck = true;
    });
  }

  Future<AppVersionPolicyModel?> _loadPolicy() async {
    final platform = _platformName();
    if (platform == null) return null;

    String? currentVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      if (version.isNotEmpty) currentVersion = version;
    } catch (error) {
      debugPrint('App version lookup failed: $error');
    }

    final result = await widget.repository.getAppVersionPolicy(
      platform: platform,
      currentVersion: currentVersion,
      language: _normalizeLanguage(widget.languageCode),
    );

    switch (result) {
      case Success(:final data):
        return data.shouldPrompt ? data : null;
      case Error(:final failure):
        debugPrint('App version policy lookup failed: ${failure.message}');
        return null;
    }
  }

  Future<void> _openStore(AppVersionPolicyModel policy) async {
    if (_openingStore) return;
    setState(() => _openingStore = true);

    final opened = await ExternalUrlLauncher.open(policy.appUrl);
    if (!mounted) return;

    setState(() => _openingStore = false);
    if (opened) {
      if (!policy.forceUpdate) setState(() => _dismissed = true);
      return;
    }

    final copy = _copyFor(widget.languageCode, force: policy.forceUpdate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(copy.openFailed),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _VersionPromptStage extends StatelessWidget {
  const _VersionPromptStage({
    required this.policy,
    required this.languageCode,
    required this.openingStore,
    required this.onUpdate,
    required this.onLater,
  });

  final AppVersionPolicyModel policy;
  final String languageCode;
  final bool openingStore;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final force = policy.forceUpdate;
    return Scaffold(
      body: Stack(
        children: [
          const _VersionSplash(),
          Positioned.fill(
            child: GestureDetector(
              onTap: force ? null : onLater,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _UpdatePolicyModal(
                  policy: policy,
                  languageCode: languageCode,
                  openingStore: openingStore,
                  onUpdate: onUpdate,
                  onLater: onLater,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatePolicyModal extends StatefulWidget {
  const _UpdatePolicyModal({
    required this.policy,
    required this.languageCode,
    required this.openingStore,
    required this.onUpdate,
    required this.onLater,
  });

  final AppVersionPolicyModel policy;
  final String languageCode;
  final bool openingStore;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  @override
  State<_UpdatePolicyModal> createState() => _UpdatePolicyModalState();
}

class _UpdatePolicyModalState extends State<_UpdatePolicyModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final force = widget.policy.forceUpdate;
    final copy = _copyFor(widget.languageCode, force: force);
    final description = widget.policy.description.trim().isNotEmpty
        ? widget.policy.description.trim()
        : copy.description;
    final latestVersion = widget.policy.latestVersion.trim();

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B19) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.16),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned(
                    right: -52,
                    top: -48,
                    child: _GlowCircle(
                      color: force ? BaseColors.danger : BaseColors.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _UpdateIcon(force: force),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    copy.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontSize: 22,
                                          height: 1.14,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1D1713),
                                        ),
                                  ),
                                  if (latestVersion.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _VersionPill(
                                      text: copy.latestVersion(latestVersion),
                                      force: force,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!force && widget.onLater != null)
                              IconButton(
                                tooltip: copy.later,
                                onPressed: widget.onLater,
                                icon: const Icon(Icons.close_rounded),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.45,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.74)
                                    : BaseColors.textGray,
                              ),
                        ),
                        if (force) ...[
                          const SizedBox(height: 14),
                          _ForceNotice(text: copy.forceNotice),
                        ],
                        const SizedBox(height: 26),
                        FilledButton.icon(
                          onPressed: widget.openingStore
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  widget.onUpdate();
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: force
                                ? BaseColors.danger
                                : BaseColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: widget.openingStore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.system_update_alt_rounded),
                          label: Text(
                            widget.openingStore ? copy.opening : copy.update,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!force && widget.onLater != null) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: widget.openingStore
                                ? null
                                : widget.onLater,
                            child: Text(copy.later),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateIcon extends StatefulWidget {
  const _UpdateIcon({required this.force});

  final bool force;

  @override
  State<_UpdateIcon> createState() => _UpdateIconState();
}

class _UpdateIconState extends State<_UpdateIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.force ? BaseColors.danger : BaseColors.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -2 * _controller.value),
          child: child,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: SizedBox(
          width: 62,
          height: 62,
          child: Icon(
            widget.force
                ? Icons.priority_high_rounded
                : Icons.rocket_launch_rounded,
            color: color,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.text, required this.force});

  final String text;
  final bool force;

  @override
  Widget build(BuildContext context) {
    final color = force ? BaseColors.danger : BaseColors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ForceNotice extends StatelessWidget {
  const _ForceNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BaseColors.danger.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaseColors.danger.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.lock_clock_rounded,
              color: BaseColors.danger,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.86)
                      : const Color(0xFF62302C),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 150, height: 150),
    );
  }
}

class _VersionSplash extends StatelessWidget {
  const _VersionSplash();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? BaseColors.black800 : BaseColors.baseBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: BaseColors.primary.withValues(alpha: 0.2),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Image.asset(
                  'assets/images/enjoy-logo.png',
                  width: 78,
                  height: 78,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _UpdateCopy = ({
  String title,
  String description,
  String update,
  String later,
  String opening,
  String openFailed,
  String forceNotice,
  String Function(String version) latestVersion,
});

_UpdateCopy _copyFor(String languageCode, {required bool force}) {
  final language = _normalizeLanguage(languageCode);
  switch (language) {
    case 'ru':
      return (
        title: force ? 'Требуется обновление' : 'Доступно обновление',
        description: force
            ? 'Чтобы продолжить пользоваться приложением, установите новую версию.'
            : 'Установите новую версию, чтобы получить последние улучшения.',
        update: 'Обновить',
        later: 'Позже',
        opening: 'Открываем...',
        openFailed: 'Не удалось открыть ссылку для обновления.',
        forceNotice: 'Это обновление обязательно. Закрыть окно нельзя.',
        latestVersion: (version) => 'Версия $version',
      );
    case 'en':
      return (
        title: force ? 'Update required' : 'Update available',
        description: force
            ? 'Install the latest version to continue using the app.'
            : 'Install the latest version to get the newest improvements.',
        update: 'Update now',
        later: 'Later',
        opening: 'Opening...',
        openFailed: 'Could not open the update link.',
        forceNotice: 'This update is required. The prompt cannot be dismissed.',
        latestVersion: (version) => 'Version $version',
      );
    case 'uz':
    default:
      return (
        title: force ? 'Yangilash majburiy' : 'Yangilanish mavjud',
        description: force
            ? "Ilovadan foydalanishni davom ettirish uchun yangi versiyani o'rnating."
            : "So'nggi yaxshilanishlarni olish uchun yangi versiyani o'rnating.",
        update: 'Yangilash',
        later: 'Keyinroq',
        opening: 'Ochilyapti...',
        openFailed: "Yangilash havolasini ochib bo'lmadi.",
        forceNotice: "Bu yangilanish majburiy. Oynani yopib bo'lmaydi.",
        latestVersion: (version) => 'Versiya $version',
      );
  }
}

String? _platformName() {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => null,
  };
}

String _normalizeLanguage(String languageCode) {
  final normalized = languageCode.toLowerCase().split(RegExp('[-_]')).first;
  return switch (normalized) {
    'ru' || 'en' || 'uz' => normalized,
    _ => 'uz',
  };
}
