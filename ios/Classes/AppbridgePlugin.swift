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
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}