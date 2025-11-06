import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator.pop()
import 'dart:ui' if (dart.library.io) 'dart:ui';
import 'dart:isolate' if (dart.library.io) 'dart:isolate';
import 'package:appbridge/appbridge.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'downloader_stub.dart' if (dart.library.io) 'downloader_io.dart';

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

  @override
  void initState() {
    super.initState();
    _bindBackgroundIsolate();
    appbridgePlugin = Appbridge(); // Initialize Appbridge here
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
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    'file:///android_asset/flutter_assets/packages/appbridge/assets/demo.html',
                  ),
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  debugPrint(
                    '[_MyAppState] _webViewController set in onWebViewCreated: $_webViewController',
                  );
                  if (appbridgePlugin != null && _webViewController != null) {
                    appbridgePlugin!.initialize(
                      _webViewController!,
                      builderContext, // Pass the current context
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
                          if (appbridgePlugin != null) {
                            appbridgePlugin?.nav?.open(
                              url: url,
                              title: title,
                            ); // Pass the title
                            appbridgePlugin?.ui?.toast(message: '加载URL: $url');
                          }
                        } else {
                          debugPrint(
                            'Error: _webViewController is null when trying to load URL via loadUrl',
                          );
                        }
                      },
                    );
                    // Add this line to call the JS function
                    _webViewController!.evaluateJavascript(
                      source: 'flutterIsReady();',
                    );
                  } else {
                    debugPrint(
                      '!!! appbridgePlugin or _webViewController is NULL in main onWebViewCreated. Appbridge not initialized. !!!',
                    );
                  }
                },
                onLoadStop: (controller, url) async {
                  debugPrint('Page finished loading: $url');
                  // The JavaScript polling for initSDK() is now handled by the web page itself.
                },
                onConsoleMessage: (controller, consoleMessage) {
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
