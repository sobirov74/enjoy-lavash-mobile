import 'dart:async';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';

const int _otpCodeLength = 4;

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen>
    with CodeAutoFill {
  final TextEditingController _phoneController = TextEditingController(
    text: '+998',
  );
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();

  bool _otpRequested = false;
  bool _isSubmitting = false;
  bool _codeHasError = false;
  String? _errorText;
  DateTime? _codeExpiresAt;
  DateTime? _requestAvailableAt;
  DateTime? _verificationAvailableAt;
  Duration _codeLifetime = Duration.zero;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _phoneController.selection = TextSelection.collapsed(
      offset: _phoneController.text.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _otpRequested) return;
      _phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unawaited(cancel());
    unawaited(unregisterListener());
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final receivedCode = _onlyDigits(code ?? '');
    if (!mounted || receivedCode.isEmpty) return;
    final normalizedCode = receivedCode.length > _otpCodeLength
        ? receivedCode.substring(0, _otpCodeLength)
        : receivedCode;

    _codeController.value = TextEditingValue(
      text: normalizedCode,
      selection: TextSelection.collapsed(offset: normalizedCode.length),
    );

    if (normalizedCode.length == _otpCodeLength) {
      unawaited(_verifyOtp());
    }
  }

  Future<void> _startSmsCodeListener() async {
    try {
      await cancel();
      await unregisterListener();
      listenForCode(smsCodeRegexPattern: r'\d{4}');
    } catch (_) {
      // Native OTP suggestions still work through AutofillHints.oneTimeCode.
    }
  }

  void _focusCodeField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _codeFocusNode.requestFocus();
    });
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  Duration _remainingUntil(DateTime? deadline) {
    if (deadline == null) return Duration.zero;
    final remaining = deadline.toUtc().difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get _isCodeExpired =>
      _otpRequested && _remainingUntil(_codeExpiresAt) == Duration.zero;

  bool get _isRequestCoolingDown =>
      _remainingUntil(_requestAvailableAt) > Duration.zero;

  bool get _isVerificationCoolingDown =>
      _remainingUntil(_verificationAvailableAt) > Duration.zero;

  bool get _hasActiveCountdown =>
      _remainingUntil(_codeExpiresAt) > Duration.zero ||
      _isRequestCoolingDown ||
      _isVerificationCoolingDown;

  String _formatCountdown(Duration duration) {
    final seconds = duration.inMilliseconds <= 0
        ? 0
        : (duration.inMilliseconds / Duration.millisecondsPerSecond).ceil();
    final minutesPart = seconds ~/ 60;
    final secondsPart = seconds % 60;
    return '${minutesPart.toString().padLeft(2, '0')}:'
        '${secondsPart.toString().padLeft(2, '0')}';
  }

  void _restartCountdownTimer() {
    _countdownTimer?.cancel();
    if (!_hasActiveCountdown) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (!_hasActiveCountdown) timer.cancel();
    });
  }

  DateTime _retryAvailableAt(RateLimitFailure failure) {
    return DateTime.now().toUtc().add(
      failure.retryAfter ?? const Duration(minutes: 1),
    );
  }

  Future<void> _requestOtp() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() => _errorText = L.of(context).enterPhoneNumber);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final controller = context.read<MobileBackendController>();
    unawaited(_startSmsCodeListener());

    final result = await controller.requestOtp(phoneNumber: phoneNumber);
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        final expiresAt = data.codeExpiresAt.toUtc();
        final codeLifetime = expiresAt.difference(DateTime.now().toUtc());
        setState(() {
          _otpRequested = true;
          _codeExpiresAt = expiresAt;
          _requestAvailableAt = expiresAt;
          _verificationAvailableAt = null;
          _codeLifetime = codeLifetime.isNegative
              ? Duration.zero
              : codeLifetime;
          _isSubmitting = false;
          _errorText = null;
          _codeHasError = false;
        });
        _restartCountdownTimer();
        _codeController.clear();
        _focusCodeField();
      case Error(:final failure):
        unawaited(cancel());
        unawaited(unregisterListener());
        if (failure is RateLimitFailure) {
          _requestAvailableAt = _retryAvailableAt(failure);
        }
        setState(() {
          _errorText = failure.message;
          _isSubmitting = false;
        });
        _restartCountdownTimer();
    }
  }

  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;

    if (_isCodeExpired) {
      setState(() {
        _errorText = L.of(context).otpCodeExpired;
        _codeHasError = true;
      });
      return;
    }
    if (_isVerificationCoolingDown) return;

    final phoneNumber = _phoneController.text.trim();
    final code = _onlyDigits(_codeController.text);
    if (code.length != _otpCodeLength) {
      setState(() {
        _errorText = L.of(context).enterSmsCode;
        _codeHasError = true;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _codeHasError = false;
    });

    final language = context.read<LocaleController>().locale.languageCode;
    final result = await context.read<MobileBackendController>().verifyOtp(
      VerifyOtpRequest(
        phoneNumber: phoneNumber,
        code: code,
        language: language,
      ),
    );
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        TextInput.finishAutofillContext();
        FocusScope.of(context).unfocus();
        await _showProfilePromptsIfNeeded(data);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      case Error(:final failure):
        if (failure is RateLimitFailure) {
          _verificationAvailableAt = _retryAvailableAt(failure);
        }
        setState(() {
          _errorText = failure.message;
          _isSubmitting = false;
          _codeHasError = true;
        });
        _restartCountdownTimer();
    }
  }

  void _onCodeChanged(String value) {
    if (!_codeHasError && _errorText == null) return;
    setState(() {
      _codeHasError = false;
      _errorText = null;
    });
  }

  Future<void> _showProfilePromptsIfNeeded(VerifyOtpResponse response) async {
    final hasName = response.client.fullName.trim().isNotEmpty;
    if (response.isNewClient || !hasName) {
      final currentName = response.client.fullName.trim();
      final initialName =
          response.isNewClient &&
              currentName == response.client.phoneNumber.trim()
          ? ''
          : currentName;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _NamePromptSheet(initialName: initialName),
      );
    }

    if (!mounted) return;
    final client =
        context.read<MobileBackendController>().client ?? response.client;
    if (client.birthDate != null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BirthDatePromptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: TypographyText(t.authorization),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: <Widget>[
              TypographyText(
                _otpRequested ? t.enterSmsCode : t.enterPhoneNumber,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TypographyText(
                _otpRequested ? t.otpSentMessage : t.signInToCheckout,
                style: const TextStyle(
                  color: BaseColors.textGray,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                autofocus: true,
                keyboardType: TextInputType.phone,
                enabled: !_otpRequested && !_isSubmitting,
                decoration: _inputDecoration(
                  label: t.phoneNumber,
                  icon: Icons.phone_outlined,
                  isDark: isDark,
                ),
              ),
              if (_otpRequested) ...[
                const SizedBox(height: 14),
                _buildOtpInput(isDark),
                const SizedBox(height: 14),
                _buildOtpTimingCard(t, isDark),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 14),
                TypographyText(
                  _errorText!,
                  style: const TextStyle(
                    color: BaseColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BaseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed:
                    _isSubmitting ||
                        (!_otpRequested && _isRequestCoolingDown) ||
                        (_otpRequested &&
                            (_isCodeExpired || _isVerificationCoolingDown))
                    ? null
                    : (_otpRequested ? _verifyOtp : _requestOtp),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : TypographyText(
                        _isVerificationCoolingDown
                            ? t.tryAgainIn(
                                _formatCountdown(
                                  _remainingUntil(_verificationAvailableAt),
                                ),
                              )
                            : !_otpRequested && _isRequestCoolingDown
                            ? t.tryAgainIn(
                                _formatCountdown(
                                  _remainingUntil(_requestAvailableAt),
                                ),
                              )
                            : _otpRequested
                            ? t.continueButton
                            : t.sendCode,
                        style: const TextStyle(color: BaseColors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpTimingCard(L t, bool isDark) {
    final codeRemaining = _remainingUntil(_codeExpiresAt);
    final resendRemaining = _remainingUntil(_requestAvailableAt);
    final canResend = !_isSubmitting && resendRemaining == Duration.zero;
    final countdown = _formatCountdown(codeRemaining);
    final totalMilliseconds = _codeLifetime.inMilliseconds;
    final progress = totalMilliseconds <= 0
        ? 0.0
        : (codeRemaining.inMilliseconds / totalMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble();

    return OtpCountdownCard(
      title: t.smsCode,
      countdown: countdown,
      semanticLabel: _isCodeExpired
          ? t.otpCodeExpired
          : t.otpCodeExpiresIn(countdown),
      expiredMessage: t.otpCodeExpired,
      resendLabel: canResend
          ? t.resendCode
          : t.resendCodeIn(_formatCountdown(resendRemaining)),
      progress: progress,
      isExpired: _isCodeExpired,
      isDark: isDark,
      onResend: canResend ? _requestOtp : null,
    );
  }

  Widget _buildOtpInput(bool isDark) {
    final fillColor = isDark ? const Color(0xFF1D1A18) : Colors.white;
    final idleBorderColor = isDark
        ? const Color(0xFF3A332D)
        : const Color(0xFFE8DED4);
    final disabledColor = isDark
        ? const Color(0xFF2A2522)
        : const Color(0xFFF1ECE6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pinSize = ((constraints.maxWidth - 30) / _otpCodeLength)
            .clamp(56.0, 64.0)
            .toDouble();
        final baseTheme = PinTheme(
          width: pinSize,
          height: pinSize,
          textStyle: TextStyle(
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF241C17),
          ),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: idleBorderColor, width: 1.4),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        );
        final primaryBorder = Border.all(color: BaseColors.primary, width: 1.8);
        final primaryTheme = baseTheme.copyDecorationWith(
          color: isDark
              ? BaseColors.primary.withValues(alpha: 0.12)
              : BaseColors.primary.withValues(alpha: 0.08),
          border: primaryBorder,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: BaseColors.primary.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        );

        return Pinput(
          length: _otpCodeLength,
          controller: _codeController,
          focusNode: _codeFocusNode,
          enabled: !_isSubmitting && !_isCodeExpired,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.oneTimeCode],
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(_otpCodeLength),
          ],
          defaultPinTheme: baseTheme,
          focusedPinTheme: primaryTheme,
          submittedPinTheme: primaryTheme,
          followingPinTheme: baseTheme,
          disabledPinTheme: baseTheme.copyDecorationWith(
            color: disabledColor,
            border: Border.all(color: idleBorderColor, width: 1.2),
          ),
          errorPinTheme: baseTheme.copyDecorationWith(
            color: BaseColors.danger.withValues(alpha: isDark ? 0.14 : 0.08),
            border: Border.all(color: BaseColors.danger, width: 1.8),
          ),
          forceErrorState: _codeHasError,
          showErrorWhenFocused: true,
          hapticFeedbackType: HapticFeedbackType.lightImpact,
          pinAnimationType: PinAnimationType.scale,
          animationDuration: const Duration(milliseconds: 180),
          closeKeyboardWhenCompleted: true,
          separatorBuilder: (_) => const SizedBox(width: 10),
          onChanged: _onCodeChanged,
          onCompleted: (_) => _verifyOtp(),
          onSubmitted: (_) => _verifyOtp(),
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDark ? const Color(0xFF1D1A18) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: BaseColors.primary),
      ),
    );
  }
}

/// Vertical OTP timing surface that keeps the countdown and resend action
/// readable without making either one compete for horizontal space.
class OtpCountdownCard extends StatelessWidget {
  const OtpCountdownCard({
    super.key,
    required this.title,
    required this.countdown,
    required this.semanticLabel,
    required this.expiredMessage,
    required this.resendLabel,
    required this.progress,
    required this.isExpired,
    required this.isDark,
    required this.onResend,
  });

  final String title;
  final String countdown;
  final String semanticLabel;
  final String expiredMessage;
  final String resendLabel;
  final double progress;
  final bool isExpired;
  final bool isDark;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final accent = isExpired ? BaseColors.danger : BaseColors.primary;
    final surface = isDark ? const Color(0xFF1D1A18) : Colors.white;
    final muted = isDark ? const Color(0xFFAAA39A) : BaseColors.textGray;
    final duration = AppMotion.duration(context, AppMotion.micro);

    return AnimatedContainer(
      key: const ValueKey<String>('otp-countdown-card'),
      duration: AppMotion.duration(context, AppMotion.state),
      curve: AppMotion.standard,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            label: semanticLabel,
            child: ExcludeSemantics(
              child: Row(
                children: <Widget>[
                  AnimatedContainer(
                    duration: AppMotion.duration(context, AppMotion.state),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isExpired
                          ? Icons.timer_off_outlined
                          : Icons.timer_outlined,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          isExpired ? expiredMessage : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isExpired ? BaseColors.danger : muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedSwitcher(
                          duration: duration,
                          switchInCurve: AppMotion.enter,
                          switchOutCurve: AppMotion.exit,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.18),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: TypographyText(
                            countdown,
                            key: ValueKey<String>(countdown),
                            style: TextStyle(
                              color: accent,
                              fontSize: 27,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(color: accent.withValues(alpha: 0.12)),
                    TweenAnimationBuilder<double>(
                      duration: duration,
                      curve: AppMotion.standard,
                      tween: Tween<double>(
                        begin: 0,
                        end: progress.clamp(0.0, 1.0),
                      ),
                      builder: (context, value, child) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          heightFactor: 1,
                          child: child,
                        ),
                      ),
                      child: ColoredBox(color: accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              key: const ValueKey<String>('otp-resend-button'),
              style: TextButton.styleFrom(
                foregroundColor: BaseColors.primary,
                backgroundColor: BaseColors.primary.withValues(
                  alpha: isDark ? 0.14 : 0.08,
                ),
                disabledForegroundColor: muted,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onResend,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: TypographyText(
                resendLabel,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NamePromptSheet extends StatefulWidget {
  const _NamePromptSheet({required this.initialName});

  final String initialName;

  @override
  State<_NamePromptSheet> createState() => _NamePromptSheetState();
}

class _NamePromptSheetState extends State<_NamePromptSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_isSaving) return;

    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final result = await context.read<MobileBackendController>().updateProfile(
      ClientProfileUpdate(fullName: fullName),
    );
    if (!mounted) return;

    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case Error(:final failure):
        setState(() {
          _isSaving = false;
          _errorText = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A332D)
                        : const Color(0xFFE8DED4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              TypographyText(
                t.nameOptional,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                enabled: !_isSaving,
                onSubmitted: (_) => _saveName(),
                decoration: InputDecoration(
                  labelText: t.nameOptional,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1D1A18) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: BaseColors.primary),
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                TypographyText(
                  _errorText!,
                  style: const TextStyle(
                    color: BaseColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: BaseColors.textGray,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: TypographyText(t.skip),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: BaseColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveName,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : TypographyText(
                              t.save,
                              style: const TextStyle(color: BaseColors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BirthDatePromptSheet extends StatefulWidget {
  const _BirthDatePromptSheet();

  @override
  State<_BirthDatePromptSheet> createState() => _BirthDatePromptSheetState();
}

class _BirthDatePromptSheetState extends State<_BirthDatePromptSheet> {
  DateTime? _selectedDate;
  bool _isSaving = false;
  String? _errorText;

  Future<void> _selectBirthDate() async {
    if (_isSaving) return;

    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 18, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      currentDate: now,
      helpText: L.of(context).birthDate,
    );
    if (!mounted || pickedDate == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
      _errorText = null;
    });
  }

  Future<void> _saveBirthDate() async {
    if (_isSaving) return;

    final birthDate = _selectedDate;
    if (birthDate == null) {
      setState(() => _errorText = L.of(context).selectBirthDate);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final result = await context.read<MobileBackendController>().updateProfile(
      ClientProfileUpdate(birthDate: birthDate),
    );
    if (!mounted) return;

    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case Error(:final failure):
        setState(() {
          _isSaving = false;
          _errorText = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final selectedDate = _selectedDate;
    final selectedDateText = selectedDate == null
        ? t.selectBirthDate
        : MaterialLocalizations.of(context).formatMediumDate(selectedDate);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 46,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A332D)
                      : const Color(0xFFE8DED4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            TypographyText(
              t.birthDateTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              button: true,
              label: t.birthDate,
              value: selectedDate == null ? null : selectedDateText,
              child: InkWell(
                key: const ValueKey<String>('birth-date-field'),
                onTap: _isSaving ? null : _selectBirthDate,
                borderRadius: BorderRadius.circular(20),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: t.birthDate,
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: const Icon(Icons.calendar_month_outlined),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1D1A18) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  child: TypographyText(
                    selectedDateText,
                    style: TextStyle(
                      color: selectedDate == null
                          ? BaseColors.textGray
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              TypographyText(
                _errorText!,
                style: const TextStyle(
                  color: BaseColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    key: const ValueKey<String>('birth-date-skip-button'),
                    style: TextButton.styleFrom(
                      foregroundColor: BaseColors.textGray,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: TypographyText(t.skip),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey<String>('birth-date-save-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: BaseColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveBirthDate,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : TypographyText(
                            t.save,
                            style: const TextStyle(color: BaseColors.white),
                          ),
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
