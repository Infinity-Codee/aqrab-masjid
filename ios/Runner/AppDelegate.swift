import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "aqrab_masjid/platform"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "openExternalUrl":
          guard
            let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String,
            let url = URL(string: urlString)
          else {
            result(FlutterError(code: "INVALID_URL", message: "Missing or invalid URL", details: nil))
            return
          }

          DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { opened in
              result(opened)
            }
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
