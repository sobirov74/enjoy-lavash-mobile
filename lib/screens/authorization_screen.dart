import 'dart:async';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:smart_auth/smart_auth.dart';

const int _otpCodeLength = 4;

Future<void> showBirthDatePromptSheet(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    showDragHandle: false,
    builder: (_) => _BirthDatePromptSheet(initialDate: initialDate),
  );
}

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key, this.smsCodeReader});

  @visibleForTesting
  final Future<String?> Function()? smsCodeReader;

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
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
  bool _smsListenerActive = false;
  int _smsListenerGeneration = 0;
  String? _pendingSmsCode;

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
    _smsListenerGeneration++;
    unawaited(SmartAuth.instance.removeUserConsentApiListener());
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _applySmsCode(String code) {
    final receivedCode = _onlyDigits(code);
    if (!mounted || receivedCode.isEmpty) return;
    final normalizedCode = receivedCode.length > _otpCodeLength
        ? receivedCode.substring(0, _otpCodeLength)
        : receivedCode;

    if (!_otpRequested || _isSubmitting) {
      _pendingSmsCode = normalizedCode;
      return;
    }

    _codeController.value = TextEditingValue(
      text: normalizedCode,
      selection: TextSelection.collapsed(offset: normalizedCode.length),
    );

    if (normalizedCode.length == _otpCodeLength) {
      unawaited(_verifyOtp());
    }
  }

  Future<void> _startSmsCodeListener() async {
    if (_smsListenerActive ||
        (widget.smsCodeReader == null &&
            (kIsWeb || defaultTargetPlatform != TargetPlatform.android))) {
      return;
    }

    _smsListenerActive = true;
    final generation = ++_smsListenerGeneration;

    try {
      final String? receivedCode;
      final reader = widget.smsCodeReader;
      if (reader != null) {
        receivedCode = await reader();
      } else {
        final result = await SmartAuth.instance.getSmsWithUserConsentApi(
          matcher: r'(?<!\d)\d{4}(?!\d)',
        );
        receivedCode = result.data?.code;
      }

      if (!mounted || generation != _smsListenerGeneration) return;
      _smsListenerActive = false;
      if (receivedCode != null) _applySmsCode(receivedCode);
    } catch (_) {
      if (mounted && generation == _smsListenerGeneration) {
        _smsListenerActive = false;
      }
      // Manual entry and native iOS OTP suggestions remain available.
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
      _codeHasError = false;
    });
    _pendingSmsCode = null;
    _codeController.clear();

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
        });
        _restartCountdownTimer();
        final pendingSmsCode = _pendingSmsCode;
        _pendingSmsCode = null;
        if (pendingSmsCode == null) {
          _focusCodeField();
        } else {
          _applySmsCode(pendingSmsCode);
        }
      case Error(:final failure):
        _pendingSmsCode = null;
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
        _smsListenerGeneration++;
        _smsListenerActive = false;
        unawaited(SmartAuth.instance.removeUserConsentApiListener());
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

  void _changePhoneNumber() {
    if (_isSubmitting) return;
    _countdownTimer?.cancel();
    _smsListenerGeneration++;
    _smsListenerActive = false;
    unawaited(SmartAuth.instance.removeUserConsentApiListener());
    setState(() {
      _otpRequested = false;
      _codeHasError = false;
      _errorText = null;
      _codeExpiresAt = null;
      _requestAvailableAt = null;
      _verificationAvailableAt = null;
      _codeLifetime = Duration.zero;
      _codeController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _phoneFocusNode.requestFocus();
      _phoneController.selection = TextSelection.collapsed(
        offset: _phoneController.text.length,
      );
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
      await showAppModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        showDragHandle: false,
        builder: (_) => _NamePromptSheet(initialName: initialName),
      );
    }

    if (!mounted) return;
    final client =
        context.read<MobileBackendController>().client ?? response.client;
    if (client.birthDate != null) return;

    await showBirthDatePromptSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => AutofillGroup(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 40).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          key: const ValueKey<String>('auth-back-button'),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const Spacer(),
                        if (_otpRequested)
                          TextButton(
                            key: const ValueKey<String>('change-phone-button'),
                            onPressed: _isSubmitting
                                ? null
                                : _changePhoneNumber,
                            child: Text(t.changePhoneNumber),
                          ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: _otpRequested ? 8 : 28,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: AppDesignTokens.cardShadow(context),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/enjoy-logo-app-icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TypographyText(
                            t.appTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.display(
                              size: 34,
                              height: 1.1,
                              color: AppDesignTokens.primaryText(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TypographyText(
                            t.authWelcomeSubtitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.ui(
                              size: 13.5,
                              height: 1.4,
                              color: AppDesignTokens.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TypographyText(
                      _otpRequested ? t.enterSmsCode : t.enterPhoneNumber,
                      style: AppTextStyles.ui(
                        size: 17,
                        height: 1.3,
                        weight: FontWeight.w600,
                        color: AppDesignTokens.primaryText(context),
                      ),
                    ),
                    if (_otpRequested) ...<Widget>[
                      const SizedBox(height: 6),
                      TypographyText(
                        t.otpSentMessage,
                        style: AppTextStyles.ui(
                          size: 13.5,
                          height: 1.4,
                          color: AppDesignTokens.secondaryText(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (!_otpRequested)
                      TextField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        enabled: !_isSubmitting,
                        decoration: _inputDecoration(
                          label: t.phoneNumber,
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                      )
                    else ...<Widget>[
                      _buildOtpInput(isDark),
                      const SizedBox(height: 14),
                      _buildOtpTimingCard(t, isDark),
                    ],
                    if (_errorText != null) ...<Widget>[
                      const SizedBox(height: 14),
                      TypographyText(
                        _errorText!,
                        style: AppTextStyles.ui(
                          size: 13,
                          weight: FontWeight.w600,
                          color: BaseColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusPill,
                        ),
                        boxShadow: AppDesignTokens.actionGlow,
                      ),
                      child: FilledButton(
                        onPressed:
                            _isSubmitting ||
                                (!_otpRequested && _isRequestCoolingDown) ||
                                (_otpRequested &&
                                    (_isCodeExpired ||
                                        _isVerificationCoolingDown))
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
                                          _remainingUntil(
                                            _verificationAvailableAt,
                                          ),
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
                    ),
                    if (!_otpRequested) ...<Widget>[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: TypographyText(t.skip),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusInput),
        borderSide: BorderSide(
          color: AppDesignTokens.controlBorder(context),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusInput),
        borderSide: BorderSide(
          color: AppDesignTokens.controlBorder(context),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusInput),
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
              AppBottomSheetDragHandle(
                margin: const EdgeInsets.only(bottom: 8),
                color: isDark
                    ? const Color(0xFF3A332D)
                    : const Color(0xFFE8DED4),
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
  const _BirthDatePromptSheet({this.initialDate});

  final DateTime? initialDate;

  @override
  State<_BirthDatePromptSheet> createState() => _BirthDatePromptSheetState();
}

class _BirthDatePromptSheetState extends State<_BirthDatePromptSheet> {
  static const int _firstYear = 1900;
  static const double _pickerItemExtent = 44;

  late final List<int> _years;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;
  late final DateTime _today;
  late DateTime _selectedDate;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _years = List<int>.generate(
      _today.year - _firstYear + 1,
      (index) => _today.year - index,
    );
    _selectedDate = _normalizedInitialDate(
      widget.initialDate ?? DateTime(_today.year - 25),
      _today,
    );
    _dayController = FixedExtentScrollController(
      initialItem: _selectedDate.day - 1,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedDate.month - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _today.year - _selectedDate.year,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  DateTime _normalizedInitialDate(DateTime date, DateTime now) {
    if (date.isAfter(now)) {
      return DateTime(now.year, now.month, now.day);
    }
    if (date.year < _firstYear) {
      return DateTime(_firstYear, 1, 1);
    }
    return DateTime(date.year, date.month, date.day);
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _availableMonths(int year) {
    return year == _today.year ? _today.month : 12;
  }

  int _availableDays(int year, int month) {
    final daysInMonth = _daysInMonth(year, month);
    if (year == _today.year && month == _today.month) {
      return _today.day;
    }
    return daysInMonth;
  }

  void _setSelectedDate({int? day, int? month, int? year}) {
    if (_isSaving) return;

    final nextYear = year ?? _selectedDate.year;
    final requestedMonth = month ?? _selectedDate.month;
    final nextMonth = requestedMonth.clamp(1, _availableMonths(nextYear));
    final requestedDay = day ?? _selectedDate.day;
    final nextDay = requestedDay.clamp(1, _availableDays(nextYear, nextMonth));
    final didClampMonth = nextMonth != requestedMonth;
    final didClampDay = nextDay != requestedDay;

    setState(() {
      _selectedDate = DateTime(nextYear, nextMonth, nextDay);
      _errorText = null;
    });
    unawaited(HapticFeedback.selectionClick());

    if (didClampMonth || didClampDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (didClampMonth && _monthController.hasClients) {
          _monthController.jumpToItem(nextMonth - 1);
        }
        if (didClampDay && _dayController.hasClients) {
          _dayController.jumpToItem(nextDay - 1);
        }
      });
    }
  }

  Future<void> _saveBirthDate() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final result = await context.read<MobileBackendController>().updateProfile(
      ClientProfileUpdate(birthDate: _selectedDate),
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selectedDateText = DateFormat.yMMMMd(locale).format(_selectedDate);
    final pickerTextStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 19,
      fontWeight: FontWeight.w700,
    );
    final pickerBackground = isDark ? const Color(0xFF1D1A18) : Colors.white;
    final pickerSelectionColor = BaseColors.primary.withValues(
      alpha: isDark ? 0.18 : 0.10,
    );

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
            AppBottomSheetDragHandle(
              margin: const EdgeInsets.only(bottom: 8),
              color: isDark ? const Color(0xFF3A332D) : const Color(0xFFE8DED4),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    t.birthDateTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey<String>('birth-date-close-button'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TypographyText(
              t.birthDateSubtitle,
              style: TextStyle(
                color: isDark ? const Color(0xFFB7AEA6) : BaseColors.textGray,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: t.birthDate,
              value: selectedDateText,
              child: Container(
                key: const ValueKey<String>('birth-date-field'),
                height: 210,
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                decoration: BoxDecoration(
                  color: pickerBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF332D29)
                        : const Color(0xFFF0E8E1),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _BirthDatePickerLabel(t.birthDateDay),
                        _BirthDatePickerLabel(t.birthDateMonth, flex: 2),
                        _BirthDatePickerLabel(t.birthDateYear),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: CupertinoPicker.builder(
                              key: const ValueKey<String>(
                                'birth-date-day-picker',
                              ),
                              scrollController: _dayController,
                              itemExtent: _pickerItemExtent,
                              useMagnifier: true,
                              magnification: 1.08,
                              selectionOverlay:
                                  CupertinoPickerDefaultSelectionOverlay(
                                    background: pickerSelectionColor,
                                  ),
                              onSelectedItemChanged: (index) =>
                                  _setSelectedDate(day: index + 1),
                              childCount: _availableDays(
                                _selectedDate.year,
                                _selectedDate.month,
                              ),
                              itemBuilder: (_, index) => Center(
                                child: Text(
                                  '${index + 1}',
                                  style: pickerTextStyle,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: CupertinoPicker.builder(
                              key: const ValueKey<String>(
                                'birth-date-month-picker',
                              ),
                              scrollController: _monthController,
                              itemExtent: _pickerItemExtent,
                              useMagnifier: true,
                              magnification: 1.08,
                              selectionOverlay:
                                  CupertinoPickerDefaultSelectionOverlay(
                                    background: pickerSelectionColor,
                                  ),
                              onSelectedItemChanged: (index) =>
                                  _setSelectedDate(month: index + 1),
                              childCount: _availableMonths(_selectedDate.year),
                              itemBuilder: (_, index) => Center(
                                child: Text(
                                  DateFormat.MMM(
                                    locale,
                                  ).format(DateTime(2000, index + 1)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: pickerTextStyle,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker.builder(
                              key: const ValueKey<String>(
                                'birth-date-year-picker',
                              ),
                              scrollController: _yearController,
                              itemExtent: _pickerItemExtent,
                              useMagnifier: true,
                              magnification: 1.08,
                              selectionOverlay:
                                  CupertinoPickerDefaultSelectionOverlay(
                                    background: pickerSelectionColor,
                                  ),
                              onSelectedItemChanged: (index) =>
                                  _setSelectedDate(year: _years[index]),
                              childCount: _years.length,
                              itemBuilder: (_, index) => Center(
                                child: Text(
                                  '${_years[index]}',
                                  style: pickerTextStyle,
                                ),
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: BaseColors.primary.withValues(
                  alpha: isDark ? 0.14 : 0.08,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.cake_outlined,
                    color: BaseColors.primary,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          t.birthDate,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFB7AEA6)
                                : BaseColors.textGray,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TypographyText(
                          selectedDateText,
                          style: const TextStyle(
                            color: BaseColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

class _BirthDatePickerLabel extends StatelessWidget {
  const _BirthDatePickerLabel(this.text, {this.flex = 1});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      flex: flex,
      child: TypographyText(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? const Color(0xFFB7AEA6) : BaseColors.textGray,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
