import Flutter
import UIKit
import flutter_downloader

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let platformChannel = FlutterMethodChannel(name: "com.example.appbridge_example/platform", binaryMessenger: controller.binaryMessenger)

    platformChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      // This is the entry point for method calls from Flutter
      switch call.method {
      case "addShortcuts":
        // Handle addShortcuts method call
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let url = args["url"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing title or url", details: nil))
          return
        }
        self.addShortcuts(title: title, url: url, result: result)
      case "setAppIcon":
        // Handle setAppIcon method call
        guard let args = call.arguments as? [String: Any],
              let styleId = args["styleId"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing styleId", details: nil))
          return
        }
        self.setAppIcon(styleId: styleId, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
        FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}

extension AppDelegate {
    func addShortcuts(title: String, url: String, result: @escaping FlutterResult) {
        if #available(iOS 9.0, *) {
            let shortcut = UIMutableApplicationShortcutItem(type: url, localizedTitle: title)
            UIApplication.shared.shortcutItems = [shortcut]
            result(true)
        } else {
            result(FlutterError(code: "UNAVAILABLE", message: "Quick Actions not available on this iOS version", details: nil))
        }
    }

    func setAppIcon(styleId: String, result: @escaping FlutterResult) {
        if #available(iOS 10.3, *) {
            if UIApplication.shared.supportsAlternateIcons {
                let iconName: String?
                switch styleId {
                case "default":
                    iconName = nil
                case "festival":
                    iconName = "FestivalIcon"
                case "blue":
                    iconName = "AppIcon-Blue"
                case "red":
                    iconName = "AppIcon-Red"
                default:
                    iconName = nil // Fallback to default icon if styleId is not recognized
                }
                UIApplication.shared.setAlternateIconName(iconName) { error in
                    if let error = error {
                        print("Error setting alternate icon: \(error.localizedDescription)")
                        result(FlutterError(code: "ICON_CHANGE_FAILED", message: error.localizedDescription, details: nil))
                    } else {
                        print("Alternate icon set successfully to \(styleId)")
                        result(true)
                    }
                }
            } else {
                result(FlutterError(code: "UNAVAILABLE", message: "Alternate icons not supported on this device", details: nil))
            }
        } else {
            result(FlutterError(code: "UNAVAILABLE", message: "Alternate icons not available on this iOS version", details: nil))
        }
    }
}
