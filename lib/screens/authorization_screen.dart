import 'dart:async';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/push_permission/presentation/push_permission_sheet.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/cover_sized_image.dart';
import 'package:enjoy_lavash_mobile/utils/format_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/failure_message.dart';

part 'auth/otp_countdown_card.dart';
part 'auth/name_prompt_sheet.dart';
part 'auth/birth_date_prompt_sheet.dart';

const int _otpCodeLength = 4;

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

  /// Bumped every second while a countdown runs; only the timing card and
  /// the main button listen. The whole screen rebuilds only when the
  /// countdown changes state (code expired, cooldown over).
  final ValueNotifier<int> _countdownTick = ValueNotifier<int>(0);
  ({bool expired, bool requestCooling, bool verificationCooling})?
  _countdownPhase;
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
    _countdownTick.dispose();
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

  ({bool expired, bool requestCooling, bool verificationCooling})
  get _currentCountdownPhase => (
    expired: _isCodeExpired,
    requestCooling: _isRequestCoolingDown,
    verificationCooling: _isVerificationCoolingDown,
  );

  void _restartCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownPhase = _currentCountdownPhase;
    if (!_hasActiveCountdown) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final phase = _currentCountdownPhase;
      if (phase != _countdownPhase) {
        _countdownPhase = phase;
        setState(() {});
      } else {
        _countdownTick.value++;
      }
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
        // Anchor the countdown to this device's clock using the lifetime the
        // server granted, so a wrong device clock cannot expire the code on
        // arrival (which used to make login impossible).
        final now = DateTime.now().toUtc();
        final codeLifetime = data.codeLifetimeFrom(now);
        final expiresAt = now.add(codeLifetime);
        setState(() {
          _otpRequested = true;
          _codeExpiresAt = expiresAt;
          _requestAvailableAt = expiresAt;
          _verificationAvailableAt = null;
          _codeLifetime = codeLifetime;
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
          _errorText = failureMessage(L.of(context), failure);
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
        // Notifications are asked for as soon as the customer is signed in:
        // the OS prompt the first time, else the in-app reminder.
        await askForPushNotificationsAfterSignIn(context, locale: language);
        if (!mounted) return;
        await _showProfilePromptsIfNeeded(data);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      case Error(:final failure):
        if (failure is RateLimitFailure) {
          _verificationAvailableAt = _retryAvailableAt(failure);
        }
        setState(() {
          _errorText = failureMessage(L.of(context), failure);
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
                            // Decoded for its 104 px slot, not at 512 px.
                            child: Image.asset(
                              'assets/images/enjoy-logo-app-icon.png',
                              fit: BoxFit.cover,
                              cacheWidth: coverDecodeExtent(
                                104,
                                MediaQuery.devicePixelRatioOf(context),
                              ),
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
                      ValueListenableBuilder<int>(
                        valueListenable: _countdownTick,
                        builder: (context, _, _) =>
                            _buildOtpTimingCard(t, isDark),
                      ),
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
                      // The label counts down a cooldown every second.
                      child: ValueListenableBuilder<int>(
                        valueListenable: _countdownTick,
                        builder: (context, _, _) => FilledButton(
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
                                            _remainingUntil(
                                              _requestAvailableAt,
                                            ),
                                          ),
                                        )
                                      : _otpRequested
                                      ? t.continueButton
                                      : t.sendCode,
                                  style: const TextStyle(
                                    color: BaseColors.white,
                                  ),
                                ),
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
    final fillColor = AppDesignTokens.surface(context);
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
      fillColor: AppDesignTokens.surface(context),
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
