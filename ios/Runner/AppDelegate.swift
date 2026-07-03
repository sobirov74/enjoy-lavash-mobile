import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var apnsToken: String?
  private var pendingApnsTokenResult: FlutterResult?

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
      guard call.method == "requestToken" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.requestApnsToken(result)
    }

    let externalUrlChannel = FlutterMethodChannel(
      name: "enjoy_lavash_mobile/external_url",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    externalUrlChannel.setMethodCallHandler { call, result in
      guard call.method == "open" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let value = call.arguments as? String,
        let url = URL(string: value)
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
    pendingApnsTokenResult?(token)
    pendingApnsTokenResult = nil
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
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
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
      [weak self] granted,
      error in
      DispatchQueue.main.async {
        guard let self else { return }
        if let error {
          self.pendingApnsTokenResult?(
            FlutterError(
              code: "APNS_AUTHORIZATION_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
          self.pendingApnsTokenResult = nil
          return
        }
        guard granted else {
          self.pendingApnsTokenResult?(nil)
          self.pendingApnsTokenResult = nil
          return
        }
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }
}
