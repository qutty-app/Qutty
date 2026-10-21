import Flutter
import UIKit
import UserNotifications

/// Bridges Apple's push service into Dart.
///
/// The client side of APNs is what makes this work for a build that is not the
/// official one: unlike FCM, APNs does not require the app to be registered in a
/// particular project and issues a device token to any app holding the push
/// entitlement, so a different bundle id does not stop a device from being
/// reachable. What this server still has to get right is the topic, which is why
/// the bundle id is reported with the token.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Must match the channel name the Dart side opens in push_transport.dart.
  private static let channelName = "qutty/apns"

  private var pushChannel: FlutterMethodChannel?

  /// A tap that arrived before Dart was listening. A notification that cold
  /// starts the app is delivered to the delegate while the Flutter engine is
  /// still starting, so invoking a method immediately would be dropped. Dart
  /// signals readiness by calling "ready", which flushes this.
  private var pendingOpenedPayload: [String: Any]?

  /// A foreground message that arrived before Dart was listening. Held for the
  /// same reason as [pendingOpenedPayload].
  private var pendingMessagePayload: [String: Any]?

  /// The device token, if it arrived before Dart was ready. Registration can
  /// complete before the engine finishes starting, and there is no way to ask
  /// for the token again, so dropping it here would leave this install
  /// permanently unregisterable.
  private var pendingToken: [String: Any]?

  private var isDartReady = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set here rather than in didInitializeImplicitFlutterEngine so a
    // notification that launched the app is not missed.
    UNUserNotificationCenter.current().delegate = self
    // This does not prompt: it only asks APNs for a token. The permission prompt
    // is raised from Dart when the user enables notifications.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard
      let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "QuttyApns")
    else { return }
    let channel = FlutterMethodChannel(
      name: AppDelegate.channelName,
      binaryMessenger: registrar.messenger()
    )
    pushChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "ready":
        // Dart has attached its listener, so anything captured during launch can
        // now be delivered.
        isDartReady = true
        if let pending = pendingToken {
          pendingToken = nil
          channel.invokeMethod("token", arguments: pending)
        }
        if let pending = pendingOpenedPayload {
          pendingOpenedPayload = nil
          channel.invokeMethod("opened", arguments: pending)
        }
        if let pending = pendingMessagePayload {
          pendingMessagePayload = nil
          channel.invokeMethod("message", arguments: pending)
        }
        result(nil)
      case "requestPermission":
        requestPermission(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Asks for alert, badge and sound permission and registers for remote
  /// notifications. The token itself arrives asynchronously in
  /// didRegisterForRemoteNotificationsWithDeviceToken.
  private func requestPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
      guard let self else {
        result(false)
        return
      }
      switch settings.authorizationStatus {
      case .notDetermined:
        askForAuthorization(result: result)
      case .denied:
        // Re-prompting after a denial is not possible, so the existing decision
        // is reported rather than asking again and being silently refused.
        result(false)
      case .authorized, .provisional, .ephemeral:
        Self.registerForRemoteNotifications()
        result(true)
      @unknown default:
        result(false)
      }
    }
  }

  private func askForAuthorization(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      if let error {
        result(
          FlutterError(
            code: "permission_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }
      guard granted else {
        result(false)
        return
      }
      Self.registerForRemoteNotifications()
      result(true)
    }
  }

  private static func registerForRemoteNotifications() {
    DispatchQueue.main.async {
      UIApplication.shared.registerForRemoteNotifications()
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // APNs tokens are opaque bytes, and the server addresses them as lowercase
    // hex, so convert here rather than asking Dart to.
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    guard !token.isEmpty else { return }

    // The bundle id and the APNs environment are reported alongside the token
    // because the server cannot infer either. The topic has to match this build
    // exactly, and a sandbox token is undeliverable in production, so guessing
    // either one produces pushes that are silently dropped.
    let payload: [String: Any] = [
      "token": token,
      "bundle_id": Bundle.main.bundleIdentifier ?? "",
      "sandbox": isSandboxBuild,
    ]

    guard isDartReady, let pushChannel else {
      pendingToken = payload
      return
    }
    pushChannel.invokeMethod("token", arguments: payload)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // Usually a missing push entitlement or a provisioning profile without the
    // APS environment. Surfacing it beats a token that silently never arrives.
    pushChannel?.invokeMethod(
      "tokenError",
      arguments: error.localizedDescription
    )
  }

  /// Whether this build registers against Apple's sandbox.
  ///
  /// The APS environment is a property of the profile the app was signed with,
  /// not of the build mode, so it is read from the embedded profile where one
  /// is present. Guessing from DEBUG would be wrong in both directions: a
  /// release build signed with a development profile gets sandbox tokens, and a
  /// debug build signed with a distribution profile gets production ones.
  /// Either mismatch produces a token the server can never deliver to.
  private var isSandboxBuild: Bool {
    if let environment = embeddedAPSEnvironment {
      return environment == "development"
    }
    // No profile to read, which is the simulator and an unsigned build. Neither
    // can register with APNs at all, so this value only affects logs.
    #if DEBUG
      return true
    #else
      return false
    #endif
  }

  /// The `aps-environment` from the embedded provisioning profile, if readable.
  ///
  /// A mobileprovision is a CMS-signed plist, and its payload is a plist in its
  /// own right, so it can be read without verifying the signature: this only
  /// needs a hint about the environment, and the signature is checked by the OS
  /// long before any push is accepted.
  private var embeddedAPSEnvironment: String? {
    guard
      let url = Bundle.main.url(
        forResource: "embedded",
        withExtension: "mobileprovision"
      ),
      let data = try? Data(contentsOf: url),
      let plist = try? PropertyListSerialization.propertyList(
        from: data,
        options: [],
        format: nil
      ) as? [String: Any],
      let entitlements = plist["Entitlements"] as? [String: Any]
    else { return nil }
    return entitlements["aps-environment"] as? String
  }

  private func deliver(_ payload: [String: Any], as method: String, pending keyPath: ReferenceWritableKeyPath<AppDelegate, [String: Any]?>) {
    guard isDartReady, let pushChannel else {
      self[keyPath: keyPath] = payload
      return
    }
    pushChannel.invokeMethod(method, arguments: payload)
  }
}

/// The `UNUserNotificationCenterDelegate` half of the bridge.
///
/// `FlutterAppDelegate` already declares conformance and supplies a forwarding
/// implementation of both methods, so these override it rather than adding a
/// second conformance, which the compiler rejects.
extension AppDelegate {
  /// Fires when the user taps a notification, including the one that cold
  /// started the app.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Only chat messages carry routing data. Strip aps so Dart sees the same
    // flat shape the FCM path produces.
    if let payload = messagePayload(from: response.notification.request.content) {
      deliver(payload, as: "opened", pending: \AppDelegate.pendingOpenedPayload)
    }
    completionHandler()
  }

  /// Fires while the app is in the foreground, where the system is offering to
  /// display the notification.
  ///
  /// The banner is deliberately not requested: this app decides whether to alert
  /// based on whether the user is already reading that conversation, and only
  /// Dart knows that. Suppressing the system banner and letting Dart raise a
  /// local notification is what keeps the rule identical across every transport.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if let payload = messagePayload(from: notification.request.content) {
      deliver(payload, as: "message", pending: \AppDelegate.pendingMessagePayload)
    }
    completionHandler([])
  }

  /// Returns the routing data of a chat message, or nil for anything else.
  ///
  /// APNs wraps a push payload in an `aps` dictionary, so the routing keys sit
  /// beside it rather than inside the notification content the plugin sees.
  private func messagePayload(from content: UNNotificationContent) -> [String: Any]? {
    // userInfo is keyed by AnyHashable, but the payload the server sends is
    // flat JSON, so every key is a string.
    var payload = content.userInfo.reduce(into: [String: Any]()) { result, entry in
      if let key = entry.key as? String {
        result[key] = entry.value
      }
    }
    payload.removeValue(forKey: "aps")
    guard let type = payload["type"] as? String, !type.isEmpty else { return nil }
    return payload
  }
}
