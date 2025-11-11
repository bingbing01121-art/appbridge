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


## example 项目如何使用父 appbridge 插件功能的详细说明：

1. 初始化：
* import 'package:appbridge/appbridge.dart'; 和 import
  'package:appbridge/src/models/bridge_response.dart'; 用于导入 appbridge
  插件的必要部分。
* Appbridge? appbridgePlugin; 声明了一个 Appbridge 类的实例。
* initState() 中的 appbridgePlugin = Appbridge(); 创建了插件实例。
* onWebViewCreated 中的 await appbridgePlugin!.initialize(...)
  是核心初始化步骤。它将 InAppWebViewController 和 BuildContext
  以及各种回调传递给插件。

2. 核心功能 - JavaScript 桥接：
* appbridge 插件旨在促进 Flutter 和在 InAppWebView 中运行的 JavaScript 之间的通信。
* onLoadStop 中的 appbridgePlugin!.injectJavaScript(); 和
  _webViewController?.evaluateJavascript(source: 'flutterIsReady();'); 表明插件将其
  JavaScript 接口注入到 WebView 中，并向 JavaScript 发出 Flutter 已准备就绪的信号。

3. 事件发送和处理：
* Flutter 到 JavaScript： 示例演示了 Flutter 如何向 JavaScript 发送事件。例如，在
  _port.listen 回调（处理 flutter_downloader
  事件）中，appbridgePlugin!.emitEvent(...) 用于向 JavaScript
  端发送下载进度、完成或失败事件。
* JavaScript 到 Flutter（通过回调）： appbridgePlugin 的 initialize
  方法接受多个回调：
    * onAddShortcut：处理来自 JavaScript
      的添加快捷方式（例如，到主屏幕）的请求。它使用 MethodChannel
      (_platformChannel) 与原生平台代码交互。
    * onAppIcon：处理来自 JavaScript 的更改应用程序图标的请求，也使用
      MethodChannel。
    * onNavClose：处理来自 JavaScript 的关闭当前导航（例如，弹出当前屏幕）的请求。
    * onNavSetTitle：根据 JavaScript 的请求更新 AppBar 标题。
    * onNavReplace：处理来自 JavaScript 的导航替换请求。
    * onNavSetBars：根据 JavaScript 请求控制 AppBar 的可见性。
    * onLoadUrl：处理来自 JavaScript 的加载新 URL 的请求，可能使用
      appbridgePlugin?.nav?.open 方法。
4. 导航模块 (`nav`)：
* onLoadUrl 中使用 appbridgePlugin?.nav?.open(...) 来打开一个新
  URL，演示了插件公开的导航功能。

5. UI 模块 (`ui`)：
* onLoadUrl 中使用 appbridgePlugin?.ui?.toast(message: '加载URL: $url'); 来显示一个
  toast 消息，演示了 UI 交互功能。

6. 平台特定交互（通过 `MethodChannel`）：
* 示例设置了一个 MethodChannel (_platformChannel) 来处理特定的原生功能，例如
  addShortcuts 和 setAppIcon，然后通过 appbridge 插件的回调将这些功能暴露给
  JavaScript 端。