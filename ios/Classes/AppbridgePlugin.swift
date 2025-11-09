import Flutter
import UIKit

public class AppbridgePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.example.appbridge_h5/app", binaryMessenger: registrar.messenger())
    let instance = AppbridgePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "setVpn":
        if let url = URL(string: "App-Prefs:root=General&path=VPN") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                result(true)
            } else {
                result(FlutterError(code: "UNAVAILABLE", message: "Cannot open VPN settings", details: nil))
            }
        } else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL for VPN settings", details: nil))
        }
    case "appIcon":
        guard UIApplication.shared.supportsAlternateIcons else {
            result(FlutterError(code: "UNSUPPORTED", message: "Alternate icons are not supported on this device.", details: nil))
            return
        }

        let args = call.arguments as? [String: Any]
        let styleId = args?["styleId"] as? String

        let iconName: String?
        if styleId == "blue" {
            iconName = "AppIcon-Blue"
        } else if styleId == "red" {
            iconName = "AppIcon-Red"
        } else {
            iconName = "FestivalIcon"
        }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                result(FlutterError(code: "ERROR", message: "Failed to set alternate icon: \(error.localizedDescription)", details: nil))
            } else {
                result(true)
            }
        }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
