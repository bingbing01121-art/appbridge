# appbridge

[![pub package](https://img.shields.io/pub/v/appbridge.svg)](https://pub.dev/packages/appbridge)

A feature-rich Flutter plugin designed to bridge H5 pages with native app interactions. It integrates core functionalities, navigation control, UI interactions, data storage, permission management, device information retrieval, content sharing, notification pushing, user authentication, file downloading, and app store integration.

## 🚀 Features

*   **CoreModule:**
    *   `getVersion`: Retrieves app version and device information.
    *   `getEnv`: Retrieves environment information (network type, app ID, etc.).
    *   `ready`: Checks if the core module is ready.
    *   `has`: Checks if a specific method exists.
    *   `getCapabilities`: Retrieves a list of all available methods.
    *   `setVpn`: Sets VPN status and configuration (via platform calls).
    *   `addShortcuts`: Adds application shortcuts (supports Android pinned shortcuts and iOS quick actions).
    *   `appIcon`: Switches app icons (via platform calls).
*   **EventsModule:**
    *   `on`: Subscribes to events.
    *   `once`: Subscribes to a one-time event.
    *   `emit`: Triggers an event.
    *   `off`: Unsubscribes from an event.
*   **AppModule:**
    *   `getStatus`: Retrieves app foreground/background status, power-saving mode, VPN, and network restriction status.
    *   `openSettings`: Opens app settings.
    *   `exit`: Exits the application.
    *   `minimize`: Minimizes the application (Android only).
    *   `update.check`: Checks for app updates (Android only).
    *   `update.apply`: Applies app updates (Android only).
*   **NavModule:**
    *   `open`: Opens a new WebView page.
    *   `close`: Closes the current navigation.
    *   `replace`: Replaces the URL and title of the current navigation page.
    *   `setTitle`: Sets the navigation bar title.
    *   `setBars`: Controls the visibility of the navigation bar.
*   **UIModule:**
    *   `toast`: Displays a Toast message.
    *   `alert`: Displays an Alert dialog.
    *   `confirm`: Displays a Confirm dialog.
    *   `actionSheet`: Displays an Action Sheet.
    *   `loading`: Shows/hides a loading indicator.
    *   `haptics`: Triggers haptic feedback.
    *   `safeArea`: Retrieves safe area insets.
*   **StorageModule:**
    *   `get`: Retrieves stored data.
    *   `set`: Stores data (supports TTL).
    *   `remove`: Removes stored data.
    *   `clear`: Clears all stored data.
*   **PermissionModule:**
    *   `check`: Checks permission status.
    *   `request`: Requests permissions.
    *   `ensure`: Ensures permissions and performs operations (e.g., notification/camera handling).
*   **DeviceModule:**
    *   `getIds`: Retrieves unique device identifiers.
    *   `getInfo`: Retrieves detailed device information.
    *   `getBattery`: Retrieves battery information.
    *   `getStorageInfo`: Retrieves storage information.
    *   `getMemoryInfo`: Retrieves memory information.
    *   `getCpuInfo`: Retrieves CPU information.
*   **ShareModule:**
    *   `open`: Invokes system sharing.
    *   `copyLink`: Copies a link to the clipboard.
    *   `get` (clipboard): Retrieves clipboard content.
    *   `set` (clipboard): Sets clipboard content.
*   **NotificationsModule:**
    *   `checkPermission`: Checks notification permissions.
    *   `showLocal`: Displays local notifications.
*   **AuthModule:**
    *   `getToken`: Retrieves a simulated Token.
    *   `refreshToken`: Refreshes a simulated Token.
*   **PaymentModule:**
    *   `pay`: Simulates a payment process and navigates to the payment information page.
*   **DownloadModule:**
    *   `start`: Starts file download.
    *   `pause`: Pauses download.
    *   `resume`: Resumes download.
    *   `cancel`: Cancels download.
    *   `status`: Retrieves download status.
    *   `list`: Retrieves download list.
    *   `m3u8`: Downloads and merges M3U8 video streams (Web not supported).
    *   `getDefaultDir`: Retrieves the default download directory.
    *   `setDefaultDir`: Sets the default download directory.
    *   `getFilePath`: Retrieves the path of a downloaded file.
    *   `download` (apk): Downloads an APK file.
    *   `install` (apk): Installs an APK file (Android only).
    *   `open` (apk): Opens an installed APK (Android only).
    *   `isInstalled` (apk): Checks if an APK is installed (Android only).
    *   `getSize` (cache): Retrieves download cache size.
    *   `clear` (cache): Clears download cache.
    *   `getThumbnail` (m3u8): Extracts a thumbnail from an M3U8 video stream (Web not supported).
*   **AppStoreModule:**
    *   `open`: Opens a specific app in the iOS App Store (iOS only).
    *   `search`: Searches for apps in the iOS App Store (iOS only).
*   **DeepLinkModule:**
    *   `open`: Opens a deep link.
    *   `parse`: Parses a deep link.
*   **LiveActivityModule:**
    *   `start`, `update`, `stop`: Live Activity features (iOS 16.1+ only, currently not implemented).
*   **TestFlightModule:**
    *   `open`: Opens a TestFlight invitation link (iOS only).
*   **VideoModule:**
    *   `open`: Opens the video player.
*   **NovelModule:**
    *   `open`: Opens the novel reader.
*   **ComicsModule:**
    *   `open`: Opens the comic reader.
*   **LiveModule:**
    *   `start`: Simulates starting a live stream.
    *   `stop`: Simulates stopping a live stream.
    *   `play`: Simulates playing a live stream.
    *   `pause`: Simulates pausing a live stream.
*   **PostModule:**
    *   `open`: Opens the post details page.

## ✨ Installation

To use this plugin, add `appbridge` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  appbridge: ^1.0.1 # Use the latest version
```

Then, run `flutter pub get` to fetch the dependencies.

### iOS Setup

1.  **Enable Background Modes:** In Xcode, go to **Signing & Capabilities** > **+ Capability** > **Background Modes**, and enable **Background fetch** and **Background processing**.
2.  **Add SQLite Library:** In Xcode, go to **Build Phases** > **Link Binary With Libraries**, and add `libsqlite3.tbd`.
3.  **Configure AppDelegate:** In your `AppDelegate.swift` file, register the `FlutterDownloaderPlugin`.

    ```swift
    import UIKit
    import Flutter
    import flutter_downloader

    @UIApplicationMain
    @objc class AppDelegate: FlutterAppDelegate {
      override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
      ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
    }

    private func registerPlugins(registry: FlutterPluginRegistry) {
        if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
            FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
        }
    }
    ```
4.  **Configure Info.plist:**
    *   Add the `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and other necessary privacy descriptions if your app uses those features.
    *   To allow HTTP requests for downloads, add the following to your `Info.plist`:
        ```xml
        <key>NSAppTransportSecurity</key>
        <dict>
            <key>NSAllowsArbitraryLoads</key>
            <true/>
        </dict>
        ```

### Android Setup

1.  **Configure AndroidManifest.xml:**
    *   Add the `REQUEST_INSTALL_PACKAGES` permission if you need to install APKs:
        ```xml
        <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
        ```
    *   Add the `DownloadedFileProvider` to open downloaded files from notifications. Make sure to replace `YOUR_APPLICATION_ID` with your actual application ID.
        ```xml
        <provider
            android:name="vn.hunghd.flutterdownloader.DownloadedFileProvider"
            android:authorities="${applicationId}.flutter_downloader.provider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/provider_paths"/>
        </provider>
        ```
    *   Add the `FlutterDownloaderInitializer` to configure the number of concurrent download tasks.
        ```xml
        <provider
            android:name="vn.hunghd.flutterdownloader.FlutterDownloaderInitializer"
            android:authorities="${applicationId}.flutter-downloader-init"
            android:exported="false">
            <meta-data
                android:name="MAX_CONCURRENT_TASKS"
                android:value="5" />
        </provider>
        ```
2.  **Create `provider_paths.xml`:** In your `android/app/src/main/res/xml` directory, create a file named `provider_paths.xml` with the following content:
    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <paths xmlns:android="http://schemas.android.com/apk/res/android">
        <external-path name="external_files" path="."/>
    </paths>
    ```

## 💻 Usage Example

Here is a basic example of how to use the `appbridge` plugin:

```dart
import 'package:flutter/material.dart';
import 'package:appbridge/appbridge.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Appbridge _appbridgePlugin = Appbridge();
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
  }

  void _initializeAppbridge(BuildContext context) {
    _appbridgePlugin.initialize(
      _webViewController!,
      context,
      onNavOpen: (url) {
        // Handle navigation open requests, e.g., push a new WebView screen
        print('Navigating to: $url');
      },
      onNavClose: () {
        // Handle navigation close requests, e.g., pop the current screen
        print('Closing current navigation');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Appbridge Plugin Example'),
        ),
        body: InAppWebView(
          initialFile: 'packages/appbridge/assets/demo.html',
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _initializeAppbridge(context);
          },
          onLoadStop: (controller, url) {
            _webViewController?.evaluateJavascript(source: 'flutterIsReady();');
          },
          onConsoleMessage: (controller, consoleMessage) {
            print(consoleMessage);
          },
        ),
      ),
    );
  }
}
```

## 🤝 Contribution

We welcome contributions to `appbridge`! If you have bug reports, feature requests, or wish to submit a Pull Request, please follow these guidelines:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature-name`).
3.  Make your changes.
4.  Write tests for your changes.
5.  Ensure your code passes `flutter analyze` and `flutter format`.
6.  Commit your changes (`git commit -m 'feat: Add new feature'`).
7.  Push to your branch (`git push origin feature/your-feature-name`).
8.  Open a Pull Request.

## 📄 License

This project is licensed under the [MIT License] - see the [LICENSE](LICENSE) file for details.
