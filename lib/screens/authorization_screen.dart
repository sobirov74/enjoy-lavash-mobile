import 'dart:async';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  bool _otpRequested = false;
  bool _isSubmitting = false;
  bool _codeHasError = false;
  String? _errorText;
  String? _demoCode;

  @override
  void dispose() {
    unawaited(cancel());
    unawaited(unregisterListener());
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
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

    final result = await context.read<MobileBackendController>().requestOtp(
      phoneNumber: phoneNumber,
    );
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _otpRequested = true;
          _demoCode = data.demoCode;
          _isSubmitting = false;
          _errorText = null;
          _codeHasError = false;
        });
        _codeController.clear();
        _focusCodeField();
        unawaited(_startSmsCodeListener());
      case Error(:final failure):
        setState(() {
          _errorText = failure.message;
          _isSubmitting = false;
        });
    }
  }

  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;

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
    final fullName = _nameController.text.trim();
    final result = await context.read<MobileBackendController>().verifyOtp(
      VerifyOtpRequest(
        phoneNumber: phoneNumber,
        code: code,
        fullName: fullName.isEmpty ? null : fullName,
        language: language,
      ),
    );
    if (!mounted) return;

    switch (result) {
      case Success():
        TextInput.finishAutofillContext();
        Navigator.of(context).pop(true);
      case Error(:final failure):
        setState(() {
          _errorText = failure.message;
          _isSubmitting = false;
          _codeHasError = true;
        });
    }
  }

  void _onCodeChanged(String value) {
    if (!_codeHasError && _errorText == null) return;
    setState(() {
      _codeHasError = false;
      _errorText = null;
    });
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
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSubmitting,
                  decoration: _inputDecoration(
                    label: t.nameOptional,
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                  ),
                ),
                if (_demoCode?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  TypographyText(
                    t.demoCode(_demoCode!),
                    style: const TextStyle(
                      color: BaseColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
                onPressed: _isSubmitting
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
                        _otpRequested ? t.continueButton : t.sendCode,
                        style: const TextStyle(color: BaseColors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
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
          enabled: !_isSubmitting,
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
