part of '../mobile_backend_controller.dart';

extension _MobileBackendAuthController on MobileBackendController {
  Future<Result<OtpRequestResponse>> _requestOtp({
    required String phoneNumber,
  }) {
    return _repository.requestOtp(phoneNumber: phoneNumber);
  }

  Future<Result<VerifyOtpResponse>> _verifyOtp(
    VerifyOtpRequest request,
  ) async {
    final result = await _repository.verifyOtp(request);
    switch (result) {
      case Success(:final data):
        _client = data.client;
        _failure = null;
        final language =
            _supportedLanguageOrNull(request.language) ?? data.client.language;
        this._startPushNotificationSync(locale: language);
        unawaited(syncClientLanguage(language: language));
        unawaited(refreshNotifications());
        if (_status == MobileBackendStatus.initial) {
          _status = MobileBackendStatus.loaded;
        }
        notifyListeners();
      case Error():
    }
    return result;
  }

  Future<Result<ClientProfile>> _updateProfile(
    ClientProfileUpdate request,
  ) async {
    final result = await _repository.updateProfile(request);
    switch (result) {
      case Success(:final data):
        _client = data;
        _failure = null;
        notifyListeners();
      case Error(:final failure):
        this._applyFailure(failure);
    }
    return result;
  }

  Future<void> _syncClientLanguage({required String language}) async {
    final normalizedLanguage = _supportedLanguageOrNull(language);
    final client = _client;
    if (normalizedLanguage == null || client == null) return;
    if (client.language == normalizedLanguage) return;

    final result = await _repository.updateProfile(
      ClientProfileUpdate(language: normalizedLanguage),
    );
    switch (result) {
      case Success(:final data):
        _client = data;
        _failure = null;
        this._startPushNotificationSync(locale: normalizedLanguage);
        notifyListeners();
      case Error(:final failure):
        this._applyFailure(failure);
        debugPrint('Client language sync failed: ${failure.message}');
    }
  }

  Future<Result<void>> _logout() async {
    try {
      await _pushNotifications.deleteRegisteredToken();
    } catch (error) {
      debugPrint('Push token cleanup failed during logout: $error');
    }
    final result = await _repository.logout();
    if (result.isSuccess) {
      await handleSessionExpired();
    }
    return result;
  }

  Future<Result<void>> _deleteAccount() async {
    _accountDeleting = true;
    notifyListeners();

    try {
      try {
        await _pushNotifications.deleteRegisteredToken();
      } catch (error) {
        debugPrint('Push token cleanup failed during account deletion: $error');
      }
      final result = await _repository.deleteAccount();
      if (result.isSuccess) {
        await handleSessionExpired();
      }
      return result;
    } finally {
      _accountDeleting = false;
      notifyListeners();
    }
  }

  Future<void> _handleSessionExpired() async {
    this._clearAuthenticatedState();
  }
}
