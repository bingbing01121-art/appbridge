import '../../appbridge.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:appbridge/src/nav_webview_screen.dart'; // New import
import '../models/bridge_response.dart'; // Import BridgeResponse
import 'base_module.dart'; // Import BaseModule

typedef NavOpenCallback = void Function(String url);
typedef NavCloseCallback = void Function();
typedef NavSetTitleCallback = void Function(String title);
typedef NavSetBarsCallback = void Function(bool visible);
typedef NavReplaceCallback = void Function(
    String url, String title); // New typedef

/// Nav模块实现
class NavModule extends BaseModule {
  NavOpenCallback? onNavOpen;
  NavCloseCallback? onNavClose;
  NavSetTitleCallback? onNavSetTitle;
  NavSetBarsCallback? onNavSetBars;
  NavReplaceCallback? onNavReplace; // New callback

  NavModule({
    this.onNavOpen,
    this.onNavClose,
    this.onNavSetTitle,
    this.onNavSetBars,
    this.onNavReplace, // Initialize new callback
  });

  // Public method to open a new page
  Future<BridgeResponse> open({required String url, String? title}) async {
    return await _open({'url': url, 'title': title});
  }

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'open':
        return await _open(params);
      case 'close':
        return await _close(params);
      case 'replace':
        return await _replace(params);
      case 'setTitle':
        return await _setTitle(params);
      case 'setBars':
        return await _setBars(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _open(Map<String, dynamic> params) async {
    final url = params['url'] as String?;
    final title = params['title'] as String? ?? '新页面'; // Get title from params
    if (url == null || url.isEmpty) {
      return BridgeResponse.error(-1, 'URL cannot be empty');
    }

    // Emit a pause event before navigating away
    Appbridge().emitEvent('app.pause', {});

    if (Appbridge().mainContext == null) {
      // Add null check
      return BridgeResponse.error(
          -1, 'Main context is not available for navigation.');
    }

    // Call the callback (if any)
    onNavOpen?.call(url);

    // Push a new screen with an InAppWebView
    Navigator.push(
      Appbridge().mainContext!, // Use mainContext for pushing new pages
      MaterialPageRoute(
        builder: (context) => NavWebViewScreen(url: url, title: title),
      ),
    );

    return BridgeResponse.success(true);
  }

  Future<BridgeResponse> _close(Map<String, dynamic> params) async {
    onNavClose?.call();
    return BridgeResponse.success(true);
  }

  Future<BridgeResponse> _replace(Map<String, dynamic> params) async {
    final url = params['url'] as String?;
    final title = params['title'] as String? ?? '导航控制';
    if (url == null || url.isEmpty) {
      return BridgeResponse.error(-1, 'URL cannot be empty');
    }
    onNavReplace?.call(url, title);
    return BridgeResponse.success(true);
  }

  Future<BridgeResponse> _setTitle(Map<String, dynamic> params) async {
    final title = params['title'] as String?;
    if (title == null) {
      return BridgeResponse.error(
          400, 'Title parameter is required for nav.setTitle');
    }
    onNavSetTitle?.call(title);
    return BridgeResponse.success();
  }

  Future<BridgeResponse> _setBars(Map<String, dynamic> params) async {
    final visible = params['visible'] as bool?;
    if (visible == null) {
      return BridgeResponse.error(
          400, 'Visible parameter is required for nav.setBars');
    }
    onNavSetBars?.call(visible);
    return BridgeResponse.success();
  }
}
