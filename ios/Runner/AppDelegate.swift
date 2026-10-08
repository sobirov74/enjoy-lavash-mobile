import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var apnsToken: String?
  private var pendingApnsTokenResult: FlutterResult?
  private var apnsChannel: FlutterMethodChannel?
  /// A notification tap that arrived before Dart asked for it (cold start).
  private var pendingOpenedNotification: [String: Any]?
  private var dartListensForNotificationTaps = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let apnsChannel = FlutterMethodChannel(
      name: "enjoy_lavash_mobile/apns",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    apnsChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "requestToken":
        self?.requestApnsToken(result)
      case "takeLaunchNotification":
        self?.dartListensForNotificationTaps = true
        result(self?.pendingOpenedNotification)
        self?.pendingOpenedNotification = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.apnsChannel = apnsChannel

    let externalUrlChannel = FlutterMethodChannel(
      name: "enjoy_lavash_mobile/external_url",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    externalUrlChannel.setMethodCallHandler { call, result in
      guard call.method == "open" else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Only web links leave the app. Dart validates first; this is the last
      // line of defence against custom schemes (tel:, sms:, app schemes).
      guard
        let value = call.arguments as? String,
        let url = URL(string: value),
        url.scheme?.lowercased() == "https",
        let host = url.host, !host.isEmpty
      else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { success in
        result(success)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    apnsToken = token
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
    pendingApnsTokenResult?(token)
    pendingApnsTokenResult = nil
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    pendingApnsTokenResult?(
      FlutterError(
        code: "APNS_REGISTRATION_FAILED",
        message: error.localizedDescription,
        details: nil
      )
    )
    pendingApnsTokenResult = nil
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // Firebase Messaging is not configured on iOS, so taps are forwarded to
  // Dart here. super is intentionally not called: the completion handler is
  // invoked exactly once below, and a plugin forwarding back to this delegate
  // could otherwise recurse.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let payload = flutterPayload(response.notification.request.content.userInfo)
    if dartListensForNotificationTaps, let apnsChannel {
      apnsChannel.invokeMethod("notificationOpened", arguments: payload)
    } else {
      pendingOpenedNotification = payload
    }
    completionHandler()
  }

  /// Custom data keys only; `aps` is presentation metadata Dart does not use.
  private func flutterPayload(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
    var payload: [String: Any] = [:]
    for (key, value) in userInfo {
      guard let key = key as? String, key != "aps" else { continue }
      payload[key] = value
    }
    return payload
  }

  private func requestApnsToken(_ result: @escaping FlutterResult) {
    if let apnsToken {
      result(apnsToken)
      return
    }
    if pendingApnsTokenResult != nil {
      result(
        FlutterError(
          code: "APNS_TOKEN_REQUEST_IN_PROGRESS",
          message: "An APNs token request is already in progress",
          details: nil
        )
      )
      return
    }

    pendingApnsTokenResult = result
    UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
      DispatchQueue.main.async {
        guard let self else { return }
        var isAuthorized = settings.authorizationStatus == .authorized ||
          settings.authorizationStatus == .provisional
        if #available(iOS 14.0, *) {
          isAuthorized = isAuthorized || settings.authorizationStatus == .ephemeral
        }
        guard isAuthorized else {
          self.pendingApnsTokenResult?(nil)
          self.pendingApnsTokenResult = nil
          return
        }
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }
}
