import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase before any plugin uses it. Without this, FCM never
    // receives a token on iOS and pushes silently fail.
    FirebaseApp.configure()

    // Foreground notification presentation — without this delegate, banners
    // arriving while the app is open are swallowed by iOS.
    UNUserNotificationCenter.current().delegate = self

    // Ask iOS for the APNs token so Firebase can map FCM → APNs.
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Hand the APNs token to FirebaseMessaging so it can pair it with the FCM token.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
