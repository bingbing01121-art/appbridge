import Flutter
import UIKit
import flutter_downloader

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var deepLinkMethodChannel: FlutterMethodChannel?
    private var initialDeepLink: URL?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let platformChannel = FlutterMethodChannel(name: "com.example.appbridge_example/platform", binaryMessenger: controller.binaryMessenger)
        deepLinkMethodChannel = FlutterMethodChannel(name: "com.example.appbridge_example/deeplink", binaryMessenger: controller.binaryMessenger)

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

        deepLinkMethodChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "openDeepLink":
                guard let args = call.arguments as? [String: Any],
                      let urlString = args["url"] as? String,
                      let url = URL(string: urlString) else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid URL", details: nil))
                    return
                }
                self.openDeepLink(url: url, result: result)
            case "parseDeepLink":
                self.parseDeepLink(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)

        // Handle deep link from launchOptions
        if let url = launchOptions?[.url] as? URL {
            initialDeepLink = url
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // For custom URL schemes
    override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        initialDeepLink = url
        deepLinkMethodChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
        return super.application(application, open: url, options: options)
    }

    // For Universal Links
    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            initialDeepLink = url
            deepLinkMethodChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
        }
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
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

    func openDeepLink(url: URL, result: @escaping FlutterResult) {
        var urlToOpen = url

        if url.scheme == "googlechrome", let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let chromeUrlString = queryItems.first(where: { $0.name == "url" })?.value,
           let extractedUrl = URL(string: chromeUrlString) {
            urlToOpen = extractedUrl
        }

        if UIApplication.shared.canOpenURL(urlToOpen) {
            UIApplication.shared.open(urlToOpen, options: [:]) { success in
                if success {
                    result(0) // Success code
                } else {
                    result(FlutterError(code: "-1", message: "Failed to open URL: \(urlToOpen.absoluteString)", details: nil))
                }
            }
        } else {
            result(FlutterError(code: "-1", message: "Cannot open URL: \(urlToOpen.absoluteString)", details: nil))
        }
    }

    func parseDeepLink(result: @escaping FlutterResult) {
        if let url = initialDeepLink {
            var queryParams: [String: String]? = nil
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                queryParams = components.queryItems?.reduce(into: [String: String]()) { (dict, item) in
                    dict[item.name] = item.value
                }
            }

            result([
                "url": url.absoluteString,
                "scheme": url.scheme,
                "host": url.host,
                "path": url.path,
                "queryParameters": queryParams
            ])
            initialDeepLink = nil // Clear after parsing
        } else {
            result(nil)
        }
    }
}
