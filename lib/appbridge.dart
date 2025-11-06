import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'appbridge_platform_interface.dart';

import 'src/models/bridge_response.dart';
import 'src/modules/core_module.dart';
import 'src/modules/events_module.dart';
import 'src/modules/app_module.dart';
import 'src/modules/nav_module.dart';
import 'src/modules/ui_module.dart';
import 'src/modules/storage_module.dart';
import 'src/modules/permission_module.dart';
import 'src/modules/device_module.dart';
import 'src/modules/share_module.dart';
import 'src/modules/notifications_module.dart';
import 'src/modules/auth_module.dart';
import 'src/modules/payment_module.dart';
import 'src/modules/download_module.dart';
import 'src/modules/appstore_module.dart';
import 'src/modules/deeplink_module.dart';
import 'src/modules/liveactivity_module.dart';
import 'src/modules/testflight_module.dart';
import 'src/modules/video_module.dart';
import 'src/modules/novel_module.dart';
import 'src/modules/comics_module.dart';
import 'src/modules/live_module.dart';
import 'src/modules/post_module.dart';

typedef LoadUrlCallback = Future<void> Function(String url, String? title);

// New class to hold callbacks for a specific WebView context
class _CallbackHandler {
  final NavOpenCallback? onNavOpen;
  final NavCloseCallback? onNavClose;
  final NavSetTitleCallback? onNavSetTitle;
  final NavSetBarsCallback? onNavSetBars;
  final NavReplaceCallback? onNavReplace;
  final LoadUrlCallback? onLoadUrl;
  final BuildContext? context;

  _CallbackHandler({
    this.onNavOpen,
    this.onNavClose,
    this.onNavSetTitle,
    this.onNavSetBars,
    this.onNavReplace,
    this.onLoadUrl,
    this.context,
  });
}

class Appbridge {
  // Singleton setup
  static final Appbridge _instance = Appbridge._internal();
  factory Appbridge() {
    return _instance;
  }
  Appbridge._internal() {
    debugPrint('Appbridge: _internal constructor called.');
    _appMethodChannel = const MethodChannel('com.example.appbridge_h5/app');
    _coreModule = CoreModule(_appMethodChannel!);
    _storageModule = StorageModule();
    _deviceModule = DeviceModule(_appMethodChannel!);
    _shareModule = ShareModule();
    _notificationsModule = NotificationsModule(emitEvent);
    _authModule = AuthModule();
    _downloadModule = DownloadModule(_appMethodChannel!, emitEvent);

    _eventsModule = EventsModule(null); // Initialize with null, will be updated
    _appModule = AppModule(_appMethodChannel!); // Context will be updated
    _navModule = NavModule(); // Context will be updated
    _uiModule = UIModule(); // Context will be updated
    _permissionModule = PermissionModule(); // Context will be updated
    _paymentModule = PaymentModule(); // Context will be updated
    _appStoreModule = AppStoreModule(_uiModule); // Context will be updated
    _deepLinkModule = DeepLinkModule(_uiModule); // Context will be updated
    _testFlightModule =
        TestFlightModule(_uiModule); // Initialize with null, will be updated
    _videoModule = VideoModule(); // Context will be updated
    _novelModule = NovelModule(); // Context will be updated
    _comicsModule = ComicsModule(); // Context will be updated
    _liveModule = LiveModule(emitEvent); // Context will be updated
    _postModule = PostModule(); // Context will be updated
    _liveActivityModule =
        LiveActivityModule(_uiModule); // Initialize with null, will be updated
  }

  InAppWebViewController? _webViewController;
  BuildContext? _mainContext; // Add main context
  bool _isReady = false;

  // Stack for callback handlers, synchronized with the webview controller stack
  final List<_CallbackHandler> _callbackStack = [];

  final List<InAppWebViewController> _activeWebViewControllers = [];

  // Getter for the currently active WebViewController
  InAppWebViewController? get _currentWebViewController =>
      _activeWebViewControllers.isNotEmpty
          ? _activeWebViewControllers.last
          : null;

  // New: Register a WebViewController when a WebView is created
  void registerWebViewController(InAppWebViewController controller) {
    debugPrint(
        'Appbridge: registerWebViewController called with controller: $controller');
    if (!_activeWebViewControllers.contains(controller)) {
      _activeWebViewControllers.add(controller);
      _webViewController = controller; // Also update the main reference
      debugPrint(
          'Appbridge: Registered new WebViewController. Total active: ${_activeWebViewControllers.length}, current: $_webViewController');
      // New: Update modules that need the webViewController
      _eventsModule?.updateWebViewController(controller);
      // Add JavaScript handler here, as it's the first time this controller is registered
      controller.addJavaScriptHandler(
        handlerName: 'AppBridge',
        callback: _handleMessage,
      );
    }
  }

  // New: Unregister a WebViewController when a WebView is disposed
  void unregisterWebViewController(InAppWebViewController controller) {
    debugPrint(
        'Appbridge: unregisterWebViewController called with controller: $controller');
    _activeWebViewControllers.remove(controller);
    if (_callbackStack.isNotEmpty) {
      _callbackStack.removeLast();
    }
    if (_activeWebViewControllers.isNotEmpty) {
      _webViewController =
          _activeWebViewControllers.last; // Revert to previous active
    } else {
      _webViewController = null; // No active WebViews
    }
    debugPrint(
        'Appbridge: Unregistered WebViewController. Total active: ${_activeWebViewControllers.length}, current: $_webViewController');
  }

  MethodChannel? _appMethodChannel;

  MethodChannel? get methodChannel => _appMethodChannel;

  CoreModule? _coreModule;
  EventsModule? _eventsModule;
  AppModule? _appModule;
  NavModule? _navModule;
  UIModule? _uiModule;
  StorageModule? _storageModule;
  PermissionModule? _permissionModule;
  DeviceModule? _deviceModule;
  ShareModule? _shareModule;
  NotificationsModule? _notificationsModule;
  AuthModule? _authModule;
  PaymentModule? _paymentModule;
  DownloadModule? _downloadModule;
  AppStoreModule? _appStoreModule;
  DeepLinkModule? _deepLinkModule;
  LiveActivityModule? _liveActivityModule;
  TestFlightModule? _testFlightModule;
  VideoModule? _videoModule;
  NovelModule? _novelModule;
  ComicsModule? _comicsModule;
  LiveModule? _liveModule;
  PostModule? _postModule;

  UIModule? get ui => _uiModule;
  NavModule? get nav => _navModule;

  Future<BridgeResponse> appIcon({required String styleId}) async {
    return await _coreModule?.handleMethod('appIcon', {'styleId': styleId}) ??
        BridgeResponse.error(-1, 'CoreModule not initialized');
  }

  Future<void> initialize(
    InAppWebViewController webViewController,
    BuildContext context, {
    NavOpenCallback? onNavOpen,
    NavCloseCallback? onNavClose,
    NavSetTitleCallback? onNavSetTitle,
    NavSetBarsCallback? onNavSetBars,
    NavReplaceCallback? onNavReplace,
    LoadUrlCallback? onLoadUrl,
  }) async {
    debugPrint(
        'Appbridge: initialize called with webViewController: $webViewController, context: $context');
    registerWebViewController(webViewController);
    _mainContext ??= context;

    // Create and push a new callback handler for the current context
    final callbackHandler = _CallbackHandler(
      onNavOpen: onNavOpen,
      onNavClose: onNavClose,
      onNavSetTitle: onNavSetTitle,
      onNavSetBars: onNavSetBars,
      onNavReplace: onNavReplace,
      onLoadUrl: onLoadUrl,
      context: context, // Pass context to callback handler
    );
    _callbackStack.add(callbackHandler);

    debugPrint('Appbridge: Context added to stack for: $context');

    // Modules will now get context from Appbridge().context, so no need to update here.
    // _uiModule?.updateContext(context);
    // _permissionModule?.updateContext(context);
    // _deepLinkModule?.updateContext(context);
    // _liveModule?.updateContext(context);
    // _videoModule?.updateContext(context);
    // _novelModule?.updateContext(context);
    // _comicsModule?.updateContext(context);
    // _postModule?.updateContext(context);

    // Update UIModule for modules that need it
    _appStoreModule?.updateUIModule(_uiModule!);
    _deepLinkModule?.updateUIModule(_uiModule!);
    _liveActivityModule?.updateUIModule(_uiModule!);
    _testFlightModule?.updateUIModule(_uiModule!);

    // Update callbacks for NavModule to use the top of the stack
    _navModule?.onNavOpen = (url) => _callbackStack.last.onNavOpen?.call(url);
    _navModule?.onNavClose = () => _callbackStack.last.onNavClose?.call();
    _navModule?.onNavSetTitle =
        (title) => _callbackStack.last.onNavSetTitle?.call(title);
    _navModule?.onNavSetBars =
        (visible) => _callbackStack.last.onNavSetBars?.call(visible);
    _navModule?.onNavReplace =
        (url, title) => _callbackStack.last.onNavReplace?.call(url, title);

    // Update onLoadUrl for content modules
    _videoModule?.onLoadUrl = (url, title) =>
        _callbackStack.last.onLoadUrl?.call(url, title) ?? Future.value();
    _novelModule?.onLoadUrl = (url, title) =>
        _callbackStack.last.onLoadUrl?.call(url, title) ?? Future.value();
    _comicsModule?.onLoadUrl = (url, title) =>
        _callbackStack.last.onLoadUrl?.call(url, title) ?? Future.value();
    _postModule?.onLoadUrl = (url, title) =>
        _callbackStack.last.onLoadUrl?.call(url, title) ?? Future.value();

    if (_webViewController != null) {
      await _injectJavaScript();
    } else {
      debugPrint(
          'Appbridge: _webViewController is null in initialize, skipping JavaScript injection.');
    }

    _isReady = true;
  }

  BuildContext? get context =>
      _callbackStack.isNotEmpty ? _callbackStack.last.context : null;
  BuildContext? get mainContext => _mainContext;

  Future<void> _injectJavaScript() async {
    debugPrint(
        'Appbridge: _injectJavaScript called. Attempting to inject JavaScript.');
    const jsCode = '''
      window.AppBridge = {
        core: {
          getVersion: (params) => _callNative('core.getVersion', params),
          getEnv: (params) => _callNative('core.getEnv', params),
          ready: (params) => _callNative('core.ready', params),
          has: (path) => _callNative('core.has', {path: path}),
          getCapabilities: (params) => _callNative('core.getCapabilities', params),
          setVpn: (params) => _callNative('core.setVpn', params),
          addShortcuts: (params) => _callNative('core.addShortcuts', params),
          appIcon: (params) => _callNative('core.appIcon', params),

        },
        events: {
          on: (event, handler) => {
            return _callNative('events.on', {event: event, handler: handler.toString()})
              .then(res => {
                if (res.data && res.data.off) {
                  return eval('(' + res.data.off + ')');
                }
                return { off: () => console.warn('Unsubscribe function not provided by native.') };
              });
          },
          once: (event, handler) => {
            return _callNative('events.once', {event: event, handler: handler.toString()})
              .then(res => {
                if (res.data && res.data.off) {
                  return eval('(' + res.data.off + ')');
                }
                return { off: () => console.warn('Unsubscribe function not provided by native.') };
              });
          },
          emit: (event, payload) => _callNative('events.emit', {event: event, payload: payload}),
          off: (event, callbackId) => _callNative('events.off', {event: event, callbackId: callbackId}),
        },
        app: {
          getStatus: (params) => _callNative('app.getStatus', params),
          openSettings: (section) => _callNative('app.openSettings', {section: section}),
          exit: (params) => _callNative('app.exit', params),
          minimize: (params) => _callNative('app.minimize', params),
          update: {
            check: (params) => _callNative('app.update.check', params),
            apply: (params) => _callNative('app.update.apply', params),
          }
        },
        nav: {
          open: (params) => _callNative('nav.open', params),
          close: (params) => _callNative('nav.close', params),
          replace: (params) => _callNative('nav.replace', params),
          setTitle: (params) => _callNative('nav.setTitle', params),
          setBars: (params) => _callNative('nav.setBars', params),
        },
        ui: {
          toast: (params) => _callNative('ui.toast', params),
          alert: (params) => _callNative('ui.alert', params),
          confirm: (params) => _callNative('ui.confirm', params),
          actionSheet: (params) => _callNative('ui.actionSheet', params),
          loading: (params) => _callNative('ui.loading', params),
          haptics: (params) => _callNative('ui.haptics', params),
          safeArea: (params) => _callNative('ui.safeArea', params),
        },
        storage: {
          get: (params) => _callNative('storage.get', params),
          set: (params) => _callNative('storage.set', params),
          remove: (params) => _callNative('storage.remove', params),
          clear: (params) => _callNative('storage.clear', params),
        },
        permission: {
          check: (params) => _callNative('permission.check', params),
          request: (params) => _callNative('permission.request', params),
          ensure: (name) => _callNative('permission.ensure', {name: name}),
        },
        device: {
          getIds: (params) => _callNative('device.getIds', params),
          getInfo: (params) => _callNative('device.getInfo', params),
          getBattery: (params) => _callNative('device.getBattery', params),
          getStorageInfo: (params) => _callNative('device.getStorageInfo', params),
          getMemoryInfo: (params) => _callNative('device.getMemoryInfo', params),
          getCpuInfo: (params) => _callNative('device.getCpuInfo', params),
        },
        share: {
          open: (params) => _callNative('share.open', params),
          copyLink: (params) => _callNative('share.copyLink', params),
        },
        clipboard: {
          get: (params) => _callNative('clipboard.get', params),
          set: (params) => _callNative('clipboard.set', params),
        },
        notifications: {
          checkPermission: (params) => _callNative('notifications.check', params),
          showLocal: (params) => _callNative('notifications.showLocal', params),
        },
        auth: {
          getToken: (params) => _callNative('auth.getToken', params),
          refreshToken: (params) => _callNative('auth.refreshToken', params),
        },
        payment: {
          pay: (params) => _callNative('payment.pay', params),
        },
        download: {
          start: (params) => _callNative('download.start', params),
          pause: (params) => _callNative('download.pause', params),
          resume: (params) => _callNative('download.resume', params),
          cancel: (params) => _callNative('download.cancel', params),
          status: (params) => _callNative('download.status', params),
          list: (params) => _callNative('download.list', params),
          m3u8: (params) => _callNative('download.m3u8', params),
          getDefaultDir: (params) => _callNative('download.getDefaultDir', params),
          setDefaultDir: (params) => _callNative('download.setDefaultDir', params),
          getFilePath: (params) => _callNative('download.getFilePath', params),
        },
        apk: {
          download: (params) => _callNative('apk.download', params),
          install: (params) => _callNative('apk.install', params),
          open: (params) => _callNative('apk.open', params),
          isInstalled: (params) => _callNative('apk.isInstalled', params),
        },
        cache: {
          getSize: (params) => _callNative('cache.getSize', params),
          clear: (params) => _callNative('cache.clear', params),
        },
        appstore: {
          open: (params) => _callNative('appstore.open', params),
          search: (params) => _callNative('appstore.search', params),
        },
        testflight: {
          open: (params) => _callNative('testflight.open', params),
        },
        deeplink: {
          open: (params) => _callNative('deeplink.open', params),
          parse: (params) => _callNative('deeplink.parse', params),
        },
        liveActivity: {
          start: (params) => _callNative('liveActivity.start', params),
          update: (params) => _callNative('liveActivity.update', params),
          stop: (params) => _callNative('liveActivity.stop', params),
        },
        video: {
          open: (params) => _callNative('video.open', params),
        },
        novel: {
          open: (params) => _callNative('novel.open', params),
        },
        comics: {
          open: (params) => _callNative('comics.open', params),
        },
        live: {
          start: (params) => _callNative('live.start', params),
          stop: (params) => _callNative('live.stop', params),
          play: (params) => _callNative('live.play', params),
          pause: (params) => _callNative('live.pause', params),
        },
        post: {
          open: (params) => _callNative('post.open', params),
        },
        // Add this new function
        triggerInitSDK: () => {
          if (typeof AppBridge !== 'undefined' && typeof AppBridge.core !== 'undefined' && typeof AppBridge.core.ready !== 'undefined') {
            initSDK(); // Call the initSDK function defined in demo.html
          } else {
            console.warn('AppBridge not fully ready to trigger initSDK.');
          }
        }
      };
      function _callNative(method, params) {
        console.log('Calling Native Method:', method);
        console.log('AppBridge JS: Attempting to call native handler "AppBridge" with method:', method, 'and params:', params);
        return new Promise((resolve, reject) => {
          const messageId = Date.now() + '_' + Math.random();
          window.addEventListener('message', function handler(event) {
            if (event.data.type === 'bridge_response' && event.data.messageId === messageId) {
              window.removeEventListener('message', handler);
              console.log('AppBridge JS: Received bridge_response for messageId:', messageId, 'response:', event.data.response);
              if (event.data.response.code === 0) {
                resolve(event.data.response);
              } else {
                reject(event.data.response);
              }
            }
          });
          window.flutter_inappwebview.callHandler('AppBridge', {
            method: method,
            params: params || {},
            messageId: messageId
          });
          console.log('AppBridge JS: Dispatched callHandler for messageId:', messageId);
        });
      }
      // Listen for flutterInAppWebViewPlatformReady before calling initSDK()
      window.addEventListener('flutterInAppWebViewPlatformReady', function(event) {
        console.log('AppBridge JS: flutterInAppWebViewPlatformReady event received. Calling initSDK().');
        initSDK();
      });
    ''';
    await _webViewController!.evaluateJavascript(source: jsCode);
    debugPrint('Appbridge: JavaScript injection complete.');
  }

  Future<void> _handleMessage(List<dynamic> args) async {
    debugPrint('Appbridge: _handleMessage called with args: $args');
    final controller = _currentWebViewController; // Get current controller
    if (controller == null) {
      debugPrint(
          'Appbridge: No active WebViewController, cannot handle message.');
      return;
    }
    try {
      final data = args[0] as Map<String, dynamic>;
      final method = data['method'] as String;
      final params = data['params'] as Map<String, dynamic>? ?? {};
      final messageId = data['messageId'] as String;
      BridgeResponse response;
      try {
        response = await _routeToModule(method, params);
      } catch (e) {
        response = BridgeResponse.error(-1, e.toString());
      }
      await _sendResponse(messageId,
          response); // _sendResponse already uses _currentWebViewController
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  Future<BridgeResponse> _routeToModule(
    String method,
    Map<String, dynamic> params,
  ) async {
    final parts = method.split('.');
    final module = parts[0];
    final action = parts.length > 1 ? parts[1] : '';
    switch (module) {
      case 'core':
        return await _coreModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'CoreModule not initialized');
      case 'events':
        return await _eventsModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'EventsModule not initialized');
      case 'app':
        return await _appModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'AppModule not initialized');
      case 'nav':
        return await _navModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'NavModule not initialized');
      case 'ui':
        return await _uiModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'UIModule not initialized');
      case 'storage':
        return await _storageModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'StorageModule not initialized');
      case 'permission':
        return await _permissionModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'PermissionModule not initialized');
      case 'device':
        return await _deviceModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'DeviceModule not initialized');
      case 'share':
        return await _shareModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'ShareModule not initialized');
      case 'clipboard':
        return await _shareModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'ShareModule not initialized');
      case 'notifications':
        return await _notificationsModule?.handleMethod(
                action, params, context) ??
            BridgeResponse.error(-1, 'NotificationsModule not initialized');
      case 'auth':
        return await _authModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'AuthModule not initialized');
      case 'payment':
        return await _paymentModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'PaymentModule not initialized');
      case 'download':
        return await _downloadModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'DownloadModule not initialized');
      case 'apk':
        return await _downloadModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'DownloadModule not initialized');
      case 'cache':
        return await _downloadModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'DownloadModule not initialized');
      case 'appstore':
        return await _appStoreModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'AppStoreModule not initialized');
      case 'deeplink':
        return await _deepLinkModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'DeepLinkModule not initialized');
      case 'liveActivity':
        return await _liveActivityModule?.handleMethod(
                action, params, context) ??
            BridgeResponse.error(-1, 'LiveActivityModule not initialized');
      case 'testflight':
        return await _testFlightModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'TestFlightModule not initialized');
      case 'video':
        return await _videoModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'VideoModule not initialized');
      case 'novel':
        return await _novelModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'NovelModule not initialized');
      case 'comics':
        return await _comicsModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'ComicsModule not initialized');
      case 'live':
        return await _liveModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'LiveModule not initialized');
      case 'post':
        return await _postModule?.handleMethod(action, params, context) ??
            BridgeResponse.error(-1, 'PostModule not initialized');
      default:
        return BridgeResponse.error(-1, 'Unknown module: $module');
    }
  }

  Future<void> _sendResponse(String messageId, BridgeResponse response) async {
    debugPrint(
        'Appbridge: _sendResponse called for messageId: $messageId, response: ${response.toJson()}');
    final responseData = {
      'type': 'bridge_response',
      'messageId': messageId,
      'response': response.toJson(),
    };
    final controller = _currentWebViewController;
    if (controller == null) {
      debugPrint(
          'Appbridge: No active WebViewController, cannot send response for messageId: $messageId');
      return;
    }
    await controller.evaluateJavascript(
      // Use controller
      source: '''
      window.dispatchEvent(new MessageEvent('message', {
        data: ${jsonEncode(responseData)}
      }));
    ''',
    );
  }

  Future<void> emitEvent(String event, dynamic payload) async {
    debugPrint(
        'Appbridge: emitEvent called for event: $event, payload: $payload');
    final controller = _currentWebViewController;
    if (controller == null) {
      debugPrint(
          'Appbridge: No active WebViewController, cannot emit event: $event');
      return;
    }
    try {
      final eventData = {
        'type': 'webview_event',
        'event': event,
        'payload': payload,
      };
      final jsCode = '''
        window.dispatchEvent(new CustomEvent('${eventData['event']}', { detail: ${jsonEncode(eventData['payload'])} }));
      ''';
      await controller.evaluateJavascript(source: jsCode); // Use controller
    } catch (e) {
      debugPrint('Error emitting event to webview: $e');
    }
  }

  bool get isReady => _isReady;

  void dispose() {
    // Clear all active controllers on main dispose
    _activeWebViewControllers.clear();
    _webViewController = null;
    // _context = null; // Removed as _context field no longer exists
    _isReady = false;
  }

  // New: Method to clear the context
  void clearContext() {
    // _context = null; // Removed as _context field no longer exists
    debugPrint('Appbridge: Context cleared.');
  }

  Future<BridgeResponse> callModuleMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    return await _routeToModule(method, params);
  }

  Future<String?> getPlatformVersion() {
    return AppbridgePlatform.instance.getPlatformVersion();
  }
}
