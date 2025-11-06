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

## ✨ Quick Start

Appbridge is a Flutter plugin project that provides a bridge for H5 pages to interact with native applications.

To use this plugin in your Flutter project, add `appbridge` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  appbridge: ^1.0.0 # Use the latest version
```

Run `flutter pub get` to fetch the dependencies.

### iOS Integration

1.  **`Info.plist` Configuration:**
    *   If your app requires access to permissions like camera or photo library, add the corresponding privacy descriptions in `Info.plist` (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, etc.).
    *   Configure URL Schemes or Universal Links if applicable.

2.  **`AppDelegate.swift` or `AppDelegate.m` Configuration:**
    *   Ensure your `AppDelegate` correctly handles native method calls from `Appbridge`.

### Android Integration

1.  **`AndroidManifest.xml` Configuration:**
    *   If your app requires specific permissions, add the `<uses-permission>` tags in `AndroidManifest.xml`.
    *   Declare Activities or Services if applicable.

2.  **`MainActivity.java` or `MainActivity.kt` Configuration:**
    *   Ensure your `MainActivity` correctly handles native method calls from `Appbridge`.

## 💻 Usage Example

以下是 `appbridge` 插件的基本使用示例：

```dart
import 'package:flutter/material.dart';
import 'package:appbridge/appbridge.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // For InAppWebViewController

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
  String _message = '点击按钮获取信息';
  InAppWebViewController? _webViewController; // Declare a controller

  @override
  void initState() {
    super.initState();
    // Initialize FlutterDownloader if you plan to use download features
    // FlutterDownloader.initialize(debug: true);
  }

  // This method would typically be called when your WebView is created and ready
  void _initializeAppbridge(BuildContext context) {
    _appbridgePlugin.initialize(
      _webViewController!, // Pass your InAppWebViewController
      context,
      onNavOpen: (url) {
        // Handle navigation open requests, e.g., push a new WebView screen
        print('Navigating to: $url');
      },
      onNavClose: () {
        // Handle navigation close requests, e.g., pop the current screen
        print('Closing current navigation');
      },
      onNavSetTitle: (title) {
        // Handle setting navigation bar title
        print('Setting title: $title');
      },
      onNavSetBars: (visible) {
        // Handle setting navigation bar visibility
        print('Setting bars visibility: $visible');
      },
      onNavReplace: (url, title) {
        // Handle navigation replace requests
        print('Replacing navigation with: $url, title: $title');
      },
      onLoadUrl: (url, title) {
        // Handle internal URL loading for modules like Video, Novel, Comics, Post
        print('Loading internal URL: $url, title: $title');
      },
    );

    // Example: Listen to custom events from H5
    _appbridgePlugin.events.on('customEvent', (payload) {
      setState(() {
        _message = '收到自定义事件: $payload';
      });
    });

    // Example: Listen to download events
    _appbridgePlugin.events.on('download.started', (payload) {
      print('Download started: $payload');
    });
    _appbridgePlugin.events.on('download_resumed', (payload) {
      print('Download resumed: $payload');
    });
    _appbridgePlugin.events.on('download_canceled', (payload) {
      print('Download canceled: $payload');
    });
    _appbridgePlugin.events.on('m3u8_download_progress', (payload) {
      print('M3U8 Download progress: $payload');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Appbridge 插件示例'),
        ),
        body: Builder(
          // Use Builder to get a context within the Scaffold
          builder: (BuildContext scaffoldContext) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('插件消息: $_message
'),
                  ElevatedButton(
                    onPressed: () async {
                      // Ensure _webViewController is initialized before calling _initializeAppbridge
                      // This is a simplified example. In a real app, _webViewController would come from an InAppWebView widget.
                      if (_webViewController == null) {
                        // For demonstration, we'll mock a controller or ensure it's set up
                        // In a real app, you'd have an InAppWebView widget that provides this.
                        print("Please ensure InAppWebViewController is initialized.");
                        return;
                      }
                      _initializeAppbridge(scaffoldContext); // Pass scaffoldContext
                      // Example: Call core module method to get app version
                      final response = await _appbridgePlugin.core.getVersion();
                      setState(() {
                        _message = '应用版本: ${response.data?['appVersion']}';
                      });
                    },
                    child: const Text('初始化 Appbridge 并获取应用版本'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call UI module to show Toast message
                      await _appbridgePlugin.ui.toast(message: '来自 Appbridge 的问候！');
                    },
                    child: const Text('显示 Toast'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Nav module to open a new page
                      await _appbridgePlugin.nav.open(url: 'https://www.google.com', title: '谷歌');
                    },
                    child: const Text('打开谷歌'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Storage module to set data
                      await _appbridgePlugin.storage.set(key: 'username', value: 'FlutterUser');
                      setState(() {
                        _message = '已设置 username 到存储';
                      });
                    },
                    child: const Text('设置存储数据'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Storage module to get data
                      final response = await _appbridgePlugin.storage.get(key: 'username');
                      setState(() {
                        _message = '获取到的 username: ${response.data?['value']}';
                      });
                    },
                    child: const Text('获取存储数据'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Permission module to request camera permission
                      final response = await _appbridgePlugin.permission.request(name: 'camera');
                      setState(() {
                        _message = '相机权限状态: ${response.data}';
                      });
                    },
                    child: const Text('请求相机权限'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Device module to get device information
                      final response = await _appbridgePlugin.device.getInfo();
                      setState(() {
                        _message = '设备型号: ${response.data?['model']}';
                      });
                    },
                    child: const Text('获取设备信息'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Share module to share text
                      await _appbridgePlugin.share.open(text: 'Hello from Appbridge!', url: 'https://pub.dev/packages/appbridge');
                    },
                    child: const Text('分享文本和链接'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Notifications module to show local notification
                      await _appbridgePlugin.notifications.showLocal(id: '1', title: 'Appbridge 通知', body: '这是一条来自 Appbridge 的通知！');
                    },
                    child: const Text('显示本地通知'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Auth module to get Token
                      final response = await _appbridgePlugin.auth.getToken();
                      setState(() {
                        _message = '获取到的 Token: ${response.data?['token']}';
                      });
                    },
                    child: const Text('获取 Token'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Payment module to simulate payment
                      await _appbridgePlugin.payment.pay(productId: 'product_123', payType: 'wechat');
                      setState(() {
                        _message = '模拟支付完成';
                      });
                    },
                    child: const Text('模拟支付'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Example: Call Download module to start download
                      await _appbridgePlugin.download.start(url: 'https://example.com/sample.apk', fileName: 'sample.apk');
                      setState(() {
                        _message = '开始下载 sample.apk';
                      });
                    },
                    child: const Text('开始下载文件'),
                  ),
                  // Add more usage examples for other modules here
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

### Detailed API Usage

#### 核心模块 (CoreModule)

```dart
// Example: Get app version information
final versionResponse = await Appbridge().core.getVersion();
print('App Version: ${versionResponse.data?['appVersion']}');

// Example: Get environment information
final envResponse = await Appbridge().core.getEnv();
print('Environment Info: ${envResponse.data}');

// Example: Check if a method exists
final hasMethod = await Appbridge().core.has(path: 'ui.toast');
print('Does ui.toast exist? $hasMethod');

// Example: Get list of all available methods
final capabilities = await Appbridge().core.getCapabilities();
print('Capabilities: $capabilities');

// Example: Switch app icons (iOS only, requires native setup)
// await Appbridge().core.appIcon(styleId: 'alternateIconName');
```

#### 事件模块 (EventsModule)

```dart
// Example: Subscribe to an event
final offFunction = Appbridge().events.on('myCustomEvent', (payload) {
  print('Received myCustomEvent: $payload');
});

// Example: Trigger an event
Appbridge().events.emit('myCustomEvent', {'data': 'Hello from Flutter!'});

// Example: Unsubscribe
// offFunction.off(); // Call the returned function to unsubscribe
```

#### 应用模块 (AppModule)

```dart
// Example: Get app status
final statusResponse = await Appbridge().app.getStatus();
print('App Status: ${statusResponse.data}');

// Example: Open app settings
await Appbridge().app.openSettings();

// Example: Exit app
// await Appbridge().app.exit();

// Example: Minimize app (Android only)
// await Appbridge().app.minimize();

// Example: Check for app updates (Android only)
final updateCheck = await Appbridge().app.update.check();
print('Update available: ${updateCheck.data?['hasUpdate']}');

// Example: Apply app updates (Android only)
// await Appbridge().app.update.apply();
```

#### 导航模块 (NavModule)

```dart
// Example: Open an external URL
await Appbridge().nav.open(url: 'https://www.example.com', title: '示例网站');

// Example: Close current navigation
// await Appbridge().nav.close();

// Example: Replace current navigation page URL
// await Appbridge().nav.replace(url: 'https://new.example.com', title: '新网站');

// Example: Set navigation bar title
// await Appbridge().nav.setTitle(title: '我的新标题');

// Example: Control navigation bar visibility
// await Appbridge().nav.setBars(visible: false);
```

#### UI 模块 (UIModule)

```dart
// Example: Show Toast message
await Appbridge().ui.toast(message: '这是一个 Toast 消息！');

// Example: Show Alert dialog
await Appbridge().ui.alert(title: '提示', message: '操作已完成。');

// Example: Show Confirm dialog
final confirmed = await Appbridge().ui.confirm(title: '确认', message: '您确定要继续吗？');
print('用户确认: $confirmed');

// Example: Show Action Sheet
final selectedOption = await Appbridge().ui.actionSheet(
  title: '选择操作',
  items: [
    {'id': 'option1', 'text': '选项一'},
    {'id': 'option2', 'text': '选项二'},
  ],
);
print('选择的选项: $selectedOption');

// Example: Show loading indicator
// final dismissLoading = await Appbridge().ui.loading(visible: true, text: '请稍候...');
// Future.delayed(Duration(seconds: 3), () => dismissLoading()); // 3秒后关闭

// Example: Trigger light haptic feedback
await Appbridge().ui.haptics(style: 'light');

// Example: Get safe area insets
final safeArea = await Appbridge().ui.safeArea();
print('安全区域: $safeArea');
```

#### 存储模块 (StorageModule)

```dart
// Example: Set a string value
await Appbridge().storage.set(key: 'user_id', value: '12345');

// Example: Set a string value with expiration (TTL 60 seconds)
await Appbridge().storage.set(key: 'session_token', value: 'abcde', ttlSec: 60);

// Example: Get a value
final userId = await Appbridge().storage.get(key: 'user_id');
print('用户ID: ${userId.data?['value']}');

// Example: Remove a value
await Appbridge().storage.remove(key: 'user_id');

// Example: Clear all storage
// await Appbridge().storage.clear();
```

#### 权限模块 (PermissionModule)

```dart
// Example: Check camera permission
final cameraStatus = await Appbridge().permission.check(name: 'camera');
print('相机权限状态: $cameraStatus');

// Example: Request photo library permission
final photoGranted = await Appbridge().permission.request(name: 'photo');
print('相册权限是否授予: $photoGranted');

// Example: Ensure notification permission and handle
final notificationResult = await Appbridge().permission.ensure(name: 'notifications');
print('通知权限处理结果: $notificationResult');
```

#### 设备模块 (DeviceModule)

```dart
// Example: Get device ID
final deviceIds = await Appbridge().device.getIds();
print('设备 ID: ${deviceIds.data?['deviceId']}');

// Example: Get detailed device information
final deviceInfo = await Appbridge().device.getInfo();
print('设备型号: ${deviceInfo.data?['model']}, OS: ${deviceInfo.data?['osVersion']}');

// Example: Get battery information
final batteryInfo = await Appbridge().device.getBattery();
print('电池电量: ${batteryInfo.data?['level']}, 充电中: ${batteryInfo.data?['charging']}');

// Example: Get storage information
final storageInfo = await Appbridge().device.getStorageInfo();
print('总存储: ${storageInfo.data?['total']} ${storageInfo.data?['unit']}');

// Example: Get memory information
final memoryInfo = await Appbridge().device.getMemoryInfo();
print('总内存: ${memoryInfo.data?['total']} ${memoryInfo.data?['unit']}');

// Example: Get CPU information
final cpuInfo = await Appbridge().device.getCpuInfo();
print('CPU 核心数: ${cpuInfo.data?['cores']}, 架构: ${cpuInfo.data?['arch']}');
```

#### 分享模块 (ShareModule)

```dart
// Example: Share text and URL
await Appbridge().share.open(text: '看看这个 Flutter 插件！', url: 'https://pub.dev/packages/appbridge');

// Example: Copy link to clipboard
await Appbridge().share.copyLink(url: 'https://pub.dev/packages/appbridge');

// Example: Get clipboard content
final clipboardContent = await Appbridge().share.getClipboard();
print('剪贴板内容: ${clipboardContent.data}');

// Example: Set clipboard content
await Appbridge().share.setClipboard(text: '这是要复制到剪贴板的文本。');
```

#### 通知模块 (NotificationsModule)

```dart
// Example: Check notification permission
final notificationPermission = await Appbridge().notifications.checkPermission();
print('通知权限已授予: $notificationPermission');

// Example: Show local notification
await Appbridge().notifications.showLocal(
  id: '101',
  title: '新消息',
  body: '您有一条新消息，请查收！',
  payload: {'page': 'messages', 'id': '555'}, // 可选的自定义数据
);
```

#### 认证模块 (AuthModule)

```dart
// Example: Get user Token
final tokenResponse = await Appbridge().auth.getToken();
print('获取到的 Token: ${tokenResponse.data?['token']}');

// Example: Refresh user Token
final refreshTokenResponse = await Appbridge().auth.refreshToken();
print('刷新后的 Token: ${refreshTokenResponse.data?['token']}');
```

#### 支付模块 (PaymentModule)

```dart
// Example: Simulate payment
final paymentResult = await Appbridge().payment.pay(productId: 'premium_sub', payType: 'alipay');
print('支付结果: ${paymentResult.data}');
```

#### 下载模块 (DownloadModule)

```dart
// Example: Start file download
final downloadTask = await Appbridge().download.start(
  url: 'https://speed.hetzner.de/100MB.bin',
  fileName: 'test_file.bin',
);
print('下载任务 ID: ${downloadTask.data?['id']}');

// Example: Get download list
final downloadList = await Appbridge().download.list();
print('下载列表: $downloadList');

// Example: Download M3U8 video (iOS/Android only)
// await Appbridge().download.m3u8(url: 'https://example.com/playlist.m3u8', id: 'my_video');

// Example: Get default download directory
final defaultDir = await Appbridge().download.getDefaultDir();
print('默认下载目录: $defaultDir');

// Example: Set default download directory
// await Appbridge().download.setDefaultDir(path: '/storage/emulated/0/Download/MyAppDownloads');

// Example: Download and install APK (Android only)
// final apkDownload = await Appbridge().download.downloadApk(url: 'https://example.com/app.apk', fileName: 'my_app.apk');
// await Appbridge().download.installApk(path: apkDownload.data?['path']);
```

#### 应用商店模块 (AppStoreModule)

```dart
// Example: Open a specific app in the iOS App Store (iOS only)
// await Appbridge().appstore.open(appId: 'YOUR_APP_ID');

// Example: Search for apps in the iOS App Store (iOS only)
// await Appbridge().appstore.search(query: 'Flutter');
```

#### 深层链接模块 (DeepLinkModule)

```dart
// Example: Open a deep link
await Appbridge().deeplink.open(url: 'myapp://path/to/feature?param=value');

// Example: Parse a deep link (usually handled at app startup)
// final parsedLink = await Appbridge().deeplink.parse();
// print('解析到的深层链接: ${parsedLink.data?['parsedLink']}');
```

#### 实时活动模块 (LiveActivityModule)

```dart
// Live Activity features are only available on iOS 16.1+ and require native implementation.
// Currently, this module only returns errors or unimplemented prompts.
// await Appbridge().liveActivity.start(activityId: 'myActivity', content: {'message': 'Starting...'});
```

#### TestFlight 模块 (TestFlightModule)

```dart
// Example: Open TestFlight invitation link (iOS only)
// await Appbridge().testflight.open(url: 'https://testflight.apple.com/join/YOUR_INVITE_CODE');
```

#### 视频模块 (VideoModule)

```dart
// Example: Open video player
// await Appbridge().video.open(url: 'https://example.com/my_video.mp4', title: '我的视频');
```

#### 小说模块 (NovelModule)

```dart
// Example: Open novel reader
// await Appbridge().novel.open(id: 'novel_123', title: '我的小说');
// await Appbridge().novel.open(url: 'https://example.com/novel/chapter1.html', title: '小说章节');
```

#### 漫画模块 (ComicsModule)

```dart
// Example: Open comic reader
// await Appbridge().comics.open(id: 'comic_456', title: '我的漫画');
// await Appbridge().comics.open(url: 'https://example.com/comics/page1.jpg', title: '漫画页面');
```

#### 直播模块 (LiveModule)

```dart
// Example: Simulate starting a live stream
// await Appbridge().live.start(id: 'live_stream_789');

// Example: Simulate playing a live stream
// await Appbridge().live.play(id: 'live_stream_789');
```

#### 帖子模块 (PostModule)

```dart
// Example: Open post details page
// await Appbridge().post.open(id: 'post_101', title: '我的帖子');
// await Appbridge().post.open(url: 'https://example.com/posts/101', title: '帖子详情');
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

## ❓ Frequently Asked Questions (FAQ)

[Add any frequently asked questions and their answers here.]

## 📞 Support

If you encounter any issues or have questions, please submit an Issue on the [GitHub repository](https://github.com/bingbing01121-art/appbridge).