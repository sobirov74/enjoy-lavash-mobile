import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationSettings {
  const PushNotificationSettings({
    required this.supported,
    required this.enabled,
    required this.userEnabled,
    required this.permissionGranted,
    required this.permissionPermanentlyDenied,
  });

  final bool supported;
  final bool enabled;
  final bool userEnabled;
  final bool permissionGranted;
  final bool permissionPermanentlyDenied;

  bool get canRequestPermission =>
      supported && !permissionGranted && !permissionPermanentlyDenied;
}

class MobilePushNotificationService {
  MobilePushNotificationService(this._apiClient);

  static const String _notificationsEnabledKey = 'push_notifications_enabled';
  static const String _registeredPushTokenKey = 'registered_push_token';
  static const String _deviceIdKey = 'push_notification_device_id';

  static const MethodChannel _apnsChannel = MethodChannel(
    'enjoy_lavash_mobile/apns',
  );

  final ApiClient _apiClient;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  String? _lastRegisteredToken;
  bool _messagingReady = false;
  bool _messagingInitialised = false;

  Dio get _dio => _apiClient.dio;

  Future<void> configureMessageHandlers() async {
    if (!await _ensureMessagingReady()) return;

    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen((
      message,
    ) {
      final notification = message.notification;
      final title = notification?.title?.trim();
      final body = notification?.body?.trim();
      final text = [
        if (title != null && title.isNotEmpty) title,
        if (body != null && body.isNotEmpty) body,
      ].join('\n');
      if (text.isNotEmpty) {
        Fluttertoast.showToast(msg: text);
      }
    });

    _openedMessageSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }
  }

  Future<PushNotificationSettings> getSettings() async {
    if (!_supportsPushNotifications) {
      return const PushNotificationSettings(
        supported: false,
        enabled: false,
        userEnabled: false,
        permissionGranted: false,
        permissionPermanentlyDenied: false,
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final userEnabled = preferences.getBool(_notificationsEnabledKey) ?? true;
    final status = await _notificationPermissionStatus();

    return _settingsFromStatus(status, userEnabled: userEnabled);
  }

  Future<PushNotificationSettings> setNotificationsEnabled(
    bool enabled, {
    String? locale,
  }) async {
    if (!_supportsPushNotifications) {
      return getSettings();
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsEnabledKey, enabled);

    if (!enabled) {
      await deleteRegisteredToken();
      final status = await _notificationPermissionStatus();
      return _settingsFromStatus(status, userEnabled: false);
    }

    final settings = await _ensureNotificationPermission();
    if (settings.enabled) {
      await syncToken(locale: locale);
      return getSettings();
    }

    return settings;
  }

  Future<void> syncToken({String? locale}) async {
    final platform = _platformName();
    if (platform == null) return;

    final settings = await _ensureNotificationPermission();
    if (!settings.enabled) return;

    final token = await _getPlatformToken();
    if (token == null || token.isEmpty) return;

    await _dio.post(
      ApiEndpoints.clientPushTokens,
      data: await _registrationPayload(
        platform: platform,
        token: token,
        locale: locale,
      ),
    );
    _lastRegisteredToken = token;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_registeredPushTokenKey, token);

    if ((platform == 'android' || platform == 'ios') &&
        _tokenRefreshSubscription == null &&
        await _ensureMessagingReady()) {
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen((newToken) {
            unawaited(_registerRefreshedToken(newToken, locale: locale));
          });
    }
  }

  Future<void> deleteRegisteredToken() async {
    final preferences = await SharedPreferences.getInstance();
    final token =
        _lastRegisteredToken ?? preferences.getString(_registeredPushTokenKey);
    if (token == null || token.isEmpty) return;

    await _dio.delete(ApiEndpoints.clientPushToken(token));
    _lastRegisteredToken = null;
    await preferences.remove(_registeredPushTokenKey);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
  }

  Future<void> _registerRefreshedToken(String token, {String? locale}) async {
    final platform = _platformName();
    if (platform == null) return;
    try {
      await _dio.post(
        ApiEndpoints.clientPushTokens,
        data: await _registrationPayload(
          platform: platform,
          token: token,
          locale: locale,
        ),
      );
      _lastRegisteredToken = token;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_registeredPushTokenKey, token);
    } on DioException catch (error) {
      debugPrint('Push token refresh registration failed: ${error.message}');
    }
  }

  Future<String?> _getPlatformToken() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _getIosToken();
      case TargetPlatform.android:
        if (!await _ensureMessagingReady()) return null;
        return FirebaseMessaging.instance.getToken();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }

  Future<Map<String, Object?>> _registrationPayload({
    required String platform,
    required String token,
    String? locale,
  }) async {
    final appVersion = await _appVersion();
    final deviceId = await _deviceId();
    return {
      'platform': platform,
      'token': token,
      'deviceId': deviceId,
      'appVersion': appVersion,
      if (locale?.trim().isNotEmpty == true) 'locale': locale!.trim(),
    };
  }

  Future<String> _appVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();
      if (version.isEmpty) return buildNumber;
      if (buildNumber.isEmpty) return version;
      return '$version+$buildNumber';
    } catch (error) {
      debugPrint('App version lookup failed for push registration: $error');
      return '';
    }
  }

  Future<String> _deviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = _random();
    final generated = [
      DateTime.now().microsecondsSinceEpoch.toRadixString(16),
      random.nextInt(0x7fffffff).toRadixString(16),
      random.nextInt(0x7fffffff).toRadixString(16),
    ].join('-');
    await preferences.setString(_deviceIdKey, generated);
    return generated;
  }

  Random _random() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  Future<String?> _requestApnsToken() async {
    try {
      return await _apnsChannel.invokeMethod<String>('requestToken');
    } on PlatformException catch (error) {
      debugPrint('APNs token request failed: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<String?> _getIosToken() async {
    final apnsToken = await _requestApnsToken();
    if (await _ensureMessagingReady()) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) return token;
      } on FirebaseException catch (error) {
        debugPrint('FCM token request failed on iOS: ${error.message}');
      } on PlatformException catch (error) {
        debugPrint('FCM token request failed on iOS: ${error.message}');
      }
    }
    return apnsToken;
  }

  Future<PushNotificationSettings> _ensureNotificationPermission() async {
    if (!_supportsPushNotifications) return getSettings();

    final preferences = await SharedPreferences.getInstance();
    final userEnabled = preferences.getBool(_notificationsEnabledKey) ?? true;
    if (!userEnabled) {
      final status = await _notificationPermissionStatus();
      return _settingsFromStatus(status, userEnabled: false);
    }

    final currentStatus = await _notificationPermissionStatus();
    if (_isPermissionGranted(currentStatus) ||
        currentStatus.isPermanentlyDenied) {
      return _settingsFromStatus(currentStatus, userEnabled: true);
    }

    final requestedStatus = await Permission.notification.request();
    return _settingsFromStatus(requestedStatus, userEnabled: true);
  }

  Future<PermissionStatus> _notificationPermissionStatus() async {
    try {
      return await Permission.notification.status;
    } on PlatformException catch (error) {
      debugPrint('Notification permission status failed: ${error.message}');
      return PermissionStatus.denied;
    } on MissingPluginException {
      return PermissionStatus.denied;
    }
  }

  PushNotificationSettings _settingsFromStatus(
    PermissionStatus status, {
    required bool userEnabled,
  }) {
    final permissionGranted = _isPermissionGranted(status);
    return PushNotificationSettings(
      supported: _supportsPushNotifications,
      enabled: userEnabled && permissionGranted,
      userEnabled: userEnabled,
      permissionGranted: permissionGranted,
      permissionPermanentlyDenied: status.isPermanentlyDenied,
    );
  }

  bool _isPermissionGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<bool> _ensureMessagingReady() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    if (_messagingInitialised) return _messagingReady;
    _messagingInitialised = true;
    try {
      await Firebase.initializeApp();
      _messagingReady = true;
    } catch (error) {
      _messagingReady = false;
      debugPrint('Firebase is not configured for push: $error');
    }
    return _messagingReady;
  }

  bool get _supportsPushNotifications {
    if (kIsWeb) return false;
    return _platformName() != null;
  }

  String? _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'order_status') {
      debugPrint('Open order from push: ${message.data['orderId']}');
      return;
    }
    if (type == 'campaign') {
      debugPrint('Open campaign from push: ${message.data['notificationId']}');
    }
  }
}
