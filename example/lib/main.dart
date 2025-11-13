import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator.pop()
import 'dart:ui' if (dart.library.io) 'dart:ui';
import 'dart:isolate' if (dart.library.io) 'dart:isolate';
import 'package:appbridge/appbridge.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'downloader_stub.dart' if (dart.library.io) 'downloader_io.dart';
import 'package:appbridge/src/models/bridge_response.dart'; // Import BridgeResponse
import 'package:quick_actions/quick_actions.dart'; // Import quick_actions

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await FlutterDownloader.initialize(debug: true);
    FlutterDownloader.registerCallback(downloadCallback);
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  InAppWebViewController? _webViewController;
  final ReceivePort _port = ReceivePort();
  Appbridge? appbridgePlugin;
  String _appBarTitle = 'JS插件 Demo';
  bool _isAppBarVisible = true;
  DateTime? _lastPopTime; // Add this field to track last back press time

  final QuickActions _quickActions = const QuickActions(); // Initialize QuickActions
  static const MethodChannel _platformChannel = MethodChannel('com.example.appbridge_example/platform'); // New MethodChannel

  @override
  void initState() {
    super.initState();
    _bindBackgroundIsolate();
    appbridgePlugin = Appbridge(); // Initialize Appbridge here
    debugPrint('[_MyAppState] Appbridge singleton instance obtained in initState.');

    _platformChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'loadShortcutUrl') {
        final String? url = call.arguments['url'];
        if (url != null) {
          final String urlToLoad = url.isEmpty
              ? 'file:///android_asset/flutter_assets/packages/appbridge/assets/demo.html' // Default initial URL
              : url;
          debugPrint('Received shortcut URL from native: $urlToLoad. Loading in webview.');
          await _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(urlToLoad)));
          return true;
        }
      }
      return false;
    });
    // Setup QuickActions listener for when app starts from a shortcut
    _quickActions.initialize((String shortcutType) {
      // ScaffoldMessenger.of(context).showSnackBar( // Removed due to context issue in initState
      //   SnackBar(content: Text('App launched via shortcut: $shortcutType')),
      // );
      debugPrint('App launched via shortcut: $shortcutType');
      // You can implement custom logic here based on shortcutType
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The appbridgePlugin.initialize call is now in onWebViewCreated
  }

  void _bindBackgroundIsolate() {
    debugPrint('[_MyAppState] _bindBackgroundIsolate called.');
    bool isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    if (!isSuccess) {
      debugPrint(
        '[_MyAppState] Failed to register downloader_send_port. It might already be registered.',
      );
      _unbindBackgroundIsolate(); // Try to unbind and re-register
      isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'downloader_send_port',
      );
      if (!isSuccess) {
        debugPrint(
          '[_MyAppState] Still failed to register downloader_send_port after unbinding. Downloads might not update.',
        );
      }
    }

    _port.listen((dynamic data) {
      debugPrint(
        '[_MyAppState] Received download data from background isolate: $data',
      );
      final id = data['id'] as String;
      final status = DownloadTaskStatus.fromInt(data['status'] as int);
      final progress = data['progress'] as int;
      final speed = data['speed'] as String;

      if (_webViewController != null && appbridgePlugin != null) {
        debugPrint(
          '[_MyAppState] appbridgePlugin and _webViewController are available. Emitting event for id: $id, status: $status, progress: $progress, speed: $speed',
        );
        if (status == DownloadTaskStatus.running) {
          appbridgePlugin!.emitEvent('download.progress', {
            'id': id,
            'status': 'downloading',
            'progress': progress,
            'speed': speed,
          });
        } else if (status == DownloadTaskStatus.complete) {
          FlutterDownloader.loadTasksWithRawQuery(
            query: 'SELECT * FROM task WHERE task_id="$id"',
          ).then((tasks) {
            if (tasks != null && tasks.isNotEmpty) {
              final task = tasks.first;
              appbridgePlugin!.emitEvent('download.completed', {
                'id': id,
                'status': 'completed',
                'progress': progress,
                'path': '${task.savedDir}/${task.filename}',
              });
            }
          });
        } else if (status == DownloadTaskStatus.failed) {
          appbridgePlugin!.emitEvent('download.failed', {
            'id': id,
            'status': 'failed',
            'progress': progress,
          });
        } else if (status == DownloadTaskStatus.canceled) {
          appbridgePlugin!.emitEvent('download.canceled', {
            'id': id,
            'status': 'canceled',
          });
        }
      } else {
        debugPrint(
          '[_MyAppState] WARNING: appbridgePlugin or _webViewController is NULL. Cannot emit download event for id: $id',
        );
      }
    });
  }

  Future<BridgeResponse> _handleOnAddShortcut(BuildContext context, String title, String url) async {
    debugPrint('[_handleOnAddShortcut] title: $title, url: $url');
    if (!mounted) return BridgeResponse.error(-1, 'Widget not mounted');
    try {
      final response = await _platformChannel.invokeMethod('addShortcuts', {'title': title, 'url': url});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?.toString() ?? 'Shortcut added successfully!')), // Display native response message
        );
      }
      return BridgeResponse.success(true); // Assuming native method returns true on success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add shortcut: ${e.toString()}')),
        );
      }
      return BridgeResponse.error(-1, 'Failed to add shortcut: ${e.toString()}');
    }
  }

  Future<BridgeResponse> _handleOnAppIcon(BuildContext context, String styleId) async {
    if (!mounted) return BridgeResponse.error(-1, 'Widget not mounted');
    try {
      await _platformChannel.invokeMethod('setAppIcon', {'styleId': styleId});
      if (mounted) {
        // Use a Builder to get a context that is a descendant of ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App icon change requested for style: $styleId')),
        );
      }
      return BridgeResponse.success(true);
    } catch (e) {
      if (mounted) {
        // Use a Builder to get a context that is a descendant of ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change app icon: ${e.toString()}')),
        );
      }
      return BridgeResponse.error(-1, 'Failed to change app icon: ${e.toString()}');
    }
  }

  void _unbindBackgroundIsolate() {
    debugPrint('[_MyAppState] _unbindBackgroundIsolate called.');
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: _isAppBarVisible ? AppBar(title: Text(_appBarTitle)) : null,
        body: Builder(
          builder: (BuildContext builderContext) {
            return PopScope(
              canPop: false, // We handle popping manually
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return; // If system already popped, do nothing

                // If WebView cannot go back, handle double-tap to exit
                final now = DateTime.now();
                if (_lastPopTime == null ||
                    now.difference(_lastPopTime!) >
                        const Duration(seconds: 2)) {
                  _lastPopTime = now;
                  if (mounted) {
                    ScaffoldMessenger.of(builderContext).showSnackBar(
                      const SnackBar(
                        content: Text('再按一次退出程序'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  // Do not pop yet
                } else {
                  // If double-tapped within 2 seconds, exit the app
                  SystemNavigator.pop(); // Use SystemNavigator.pop() to exit the app
                }

                if (_webViewController != null) {
                  // If WebView can go back, navigate within WebView
                  if (await _webViewController!.canGoBack()) {
                    _webViewController!.goBack();
                    return; // Prevent app from exiting
                  }
                }
              },
              child: InAppWebView(
                initialFile: 'packages/appbridge/assets/demo.html',
                initialSettings: InAppWebViewSettings(
                  // Common settings
                  javaScriptCanOpenWindowsAutomatically: true,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  // iOS-specific optimizations
                  allowsLinkPreview: false,
                  // suppressesIncrementalRendering: true, // May improve initial load, but causes issues on some iOS versions
                  limitsNavigationsToAppBoundDomains: true,
                  directionality: WebViewDirectionality.ltr, // Explicitly set directionality
                  // Navigation control
                  useOnNavigationResponse: true,
                  useShouldOverrideUrlLoading: true,
                ),
                onWebViewCreated: (controller) async {
                  _webViewController = controller;
                  debugPrint(
                    '[_MyAppState] _webViewController set in onWebViewCreated: $_webViewController',
                  );
                  if (appbridgePlugin != null && _webViewController != null) {
                    await appbridgePlugin!.initialize(
                      _webViewController!,
                      builderContext, // Pass the current context
                      onAddShortcut: (title, url) => _handleOnAddShortcut(builderContext, title, url),
                      onAppIcon: (styleId) => _handleOnAppIcon(builderContext, styleId),
                      onNavClose: () {
                        debugPrint(
                          '>>> NavCloseCallback triggered at ${DateTime.now()} <<<',
                        );
                        if (!mounted) return;
                        Navigator.of(builderContext).pop();
                        debugPrint(
                          '>>> Navigator.pop() called in NavCloseCallback <<<',
                        );
                      },
                      onNavSetTitle: (title) {
                        setState(() {
                          _appBarTitle = title;
                        });
                      },
                      onNavReplace: (url, title) {
                        debugPrint('onNavReplace---url=$url+“;title=”+$title');
                      },
                      onNavSetBars: (visible) {
                        setState(() {
                          _isAppBarVisible = visible;
                        });
                      },
                      onLoadUrl: (url, title) async {
                        if (_webViewController != null) {
                          debugPrint('Loading URL directly in WebView: $url');
                          await _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
                          appbridgePlugin?.ui?.toast(message: '加载URL: $url');
                        } else {
                          debugPrint(
                            'Error: _webViewController is null when trying to load URL via onLoadUrl',
                          );
                        }
                      },
                    );
                    // This call is now being moved to onLoadStop
                  } else {
                    debugPrint(
                      '!!! appbridgePlugin or _webViewController is NULL in main onWebViewCreated. Appbridge not initialized. !!!',
                    );
                  }
                },
                onLoadStop: (controller, url) async {
                                  debugPrint('Page finished loading: $url');
                                  if (appbridgePlugin != null) {
                                    await appbridgePlugin!.injectJavaScript();
                                    _webViewController?.evaluateJavascript(
                                      source: 'flutterIsReady();',
                                    );
                                  }
                                },                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('Console Message: ${consoleMessage.message}');
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
