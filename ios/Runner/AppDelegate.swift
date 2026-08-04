import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Key comes from ios/Flutter/Secrets.xcconfig (gitignored) via the
    // GoogleMapsApiKey entry in Info.plist, so it never appears in source.
    // The "$(" check catches an unsubstituted placeholder — i.e. the xcconfig
    // is missing — so it fails loudly in the log instead of silently.
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
       !mapsKey.isEmpty,
       !mapsKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(mapsKey)
    } else {
      NSLog("⚠️ [KEYS] GoogleMapsApiKey missing — copy ios/Flutter/Secrets.example.xcconfig to Secrets.xcconfig. Maps will be blank.")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
