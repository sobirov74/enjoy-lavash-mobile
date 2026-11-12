part of '../mobile_backend_controller.dart';

extension _MobileBackendAuthController on MobileBackendController {
  Future<Result<OtpRequestResponse>> _requestOtp({
    required String phoneNumber,
  }) {
    return _repository.requestOtp(phoneNumber: phoneNumber);
  }

  Future<Result<VerifyOtpResponse>> _verifyOtp(VerifyOtpRequest request) async {
    final result = await _repository.verifyOtp(request);
    switch (result) {
      case Success(:final data):
        _sessionGeneration++;
        _client = data.client;
        _failure = null;
        final language =
            _supportedLanguageOrNull(request.language) ?? data.client.language;
        // Registers right away when notifications are already allowed; the
        // sign-in screen asks for them (requestFirstPushNotificationPrompt,
        // else the in-app reminder).
        _startPushNotificationSync(locale: language);
        unawaited(syncClientLanguage(language: language));
        unawaited(refreshNotifications());
        unawaited(refreshAssignedPromotions(language: language));
        unawaited(refreshLoyaltyWallet());
        if (_status == MobileBackendStatus.initial) {
          _status = MobileBackendStatus.loaded;
        }
        _notifyListeners();
      case Error():
    }
    return result;
  }

  Future<Result<ClientProfile>> _updateProfile(
    ClientProfileUpdate request,
  ) async {
    final generation = _sessionGeneration;
    final result = await _repository.updateProfile(request);
    if (!_isCurrentSession(generation)) return result;
    switch (result) {
      case Success(:final data):
        _client = data;
        _failure = null;
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure);
    }
    return result;
  }

  Future<void> _syncClientLanguage({required String language}) async {
    final normalizedLanguage = _supportedLanguageOrNull(language);
    final client = _client;
    if (normalizedLanguage == null || client == null) return;
    if (client.language == normalizedLanguage) return;

    final generation = _sessionGeneration;
    final result = await _repository.updateProfile(
      ClientProfileUpdate(language: normalizedLanguage),
    );
    if (!_isCurrentSession(generation)) return;
    switch (result) {
      case Success(:final data):
        _client = data;
        _failure = null;
        _startPushNotificationSync(locale: normalizedLanguage);
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure);
        debugPrint('Client language sync failed: ${failure.message}');
    }
  }

  Future<Result<void>> _logout() async {
    try {
      await _pushNotifications.deleteRegisteredToken();
    } catch (error) {
      debugPrint('Push token cleanup failed during logout: $error');
    } finally {
      await _pushNotifications.clearLocalRegistration();
    }
    final result = await _repository.logout();
    if (result.isSuccess) _endSession(SessionEndReason.signedOut);
    return result;
  }

  Future<Result<void>> _deleteAccount() async {
    _accountDeleting = true;
    _notifyListeners();

    try {
      final result = await _repository.deleteAccount();
      if (result.isSuccess) {
        await _pushNotifications.clearLocalRegistration(resetDeviceId: true);
        _endSession(SessionEndReason.accountDeleted);
      }
      return result;
    } finally {
      _accountDeleting = false;
      _notifyListeners();
    }
  }

  Future<void> _handleSessionExpired() async {
    // The server rejected the session, so the device registration can no
    // longer be removed remotely; forget it locally so the next sign-in
    // registers the token for whoever signs in.
    _endSession(SessionEndReason.expired);
    try {
      await _pushNotifications.clearLocalRegistration();
    } catch (error) {
      debugPrint('Push registration cleanup failed: ${error.runtimeType}');
    }
  }
}
