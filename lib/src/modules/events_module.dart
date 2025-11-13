import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';

/// Events模块实现
class EventsModule extends BaseModule {
  InAppWebViewController? _webViewController;

  // Map to store event listeners. Key: eventName, Value: Map of callbackId to handler function (JS function reference)
  final Map<String, Map<String, String>> _eventListeners = {};

  // Counter for unique callback IDs
  int _callbackIdCounter = 0;

  EventsModule(this._webViewController);

  void updateWebViewController(InAppWebViewController? controller) {
    _webViewController = controller;
  }

  // Map for method dispatch
  late final Map<String, Future<BridgeResponse> Function(Map<String, dynamic>)> _actions = {
    'on': _on,
    'once': _once,
    'emit': _emit,
    'off': _off,
  };

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    if (_actions.containsKey(action)) {
      return await _actions[action]!(params);
    }
    return BridgeResponse.error(-1, 'Unknown action: $action');
  }

  Future<BridgeResponse> _on(Map<String, dynamic> params) async {
    final event = params['event'] as String?;
    // The 'handler' param from H5 will be a string representing the JS function to call
    final jsHandler = params['handler'] as String?;

    if (event == null || jsHandler == null) {
      return BridgeResponse.error(-1, 'Event name and handler are required');
    }

    final callbackId = 'flutter_cb_${_callbackIdCounter++}';
    _eventListeners.putIfAbsent(event, () => {});
    _eventListeners[event]![callbackId] = jsHandler;

    // Return a function to H5 that can be called to unsubscribe
    // This function will be a JS snippet that calls back to Flutter to remove the listener
    final unsubscribeJs = '''
      (function() {
        const callbackId = '$callbackId';
        const event = '$event';
        return function() {
          window.flutter_inappwebview.callHandler('AppBridge', {
            method: 'events.off',
            params: { event: event, callbackId: callbackId }
          });
        };
      })() // Self-executing
    ''';
    return BridgeResponse.success({'off': unsubscribeJs});
  }

  Future<BridgeResponse> _once(Map<String, dynamic> params) async {
    final event = params['event'] as String?;
    final jsHandler = params['handler'] as String?;

    if (event == null || jsHandler == null) {
      return BridgeResponse.error(-1, 'Event name and handler are required');
    }

    final callbackId = 'flutter_cb_once_${_callbackIdCounter++}';
    _eventListeners.putIfAbsent(event, () => {});
    _eventListeners[event]![callbackId] = jsHandler;

    // For 'once', we need to wrap the handler to remove itself after execution
    final wrappedJsHandler = '''
      (function() {
        const originalHandler = $jsHandler;
        const callbackId = '$callbackId';
        const event = '$event';
        return function(payload) {
          originalHandler(payload);
          window.flutter_inappwebview.callHandler('AppBridge', {
            method: 'events.off',
            params: { event: event, callbackId: callbackId }
          });
        };
      })();
    ''';
    _eventListeners[event]![callbackId] =
        wrappedJsHandler; // Store the wrapped handler

    final unsubscribeJs = '''
      (function() {
        const callbackId = '$callbackId';
        const event = '$event';
        return function() {
          window.flutter_inappwebview.callHandler('AppBridge', {
            method: 'events.off',
            params: { event: event, callbackId: callbackId }
          });
        };
      })() // Self-executing
    ''';
    return BridgeResponse.success({'off': unsubscribeJs});
  }

  Future<BridgeResponse> _emit(Map<String, dynamic> params) async {
    final event = params['event'] as String?;

    if (event == null) {
      return BridgeResponse.error(-1, 'Event name is required');
    }

    if (_eventListeners.containsKey(event)) {
      for (final callbackId in _eventListeners[event]!.keys) {
        final jsHandler = _eventListeners[event]![callbackId];
        if (jsHandler != null) {
          // Execute the JS handler in the WebView
          await _webViewController?.evaluateJavascript(
            source: '''
            (function() {
              const handler = $jsHandler;
              handler(${jsonEncode(params['payload'])});
            })();
          ''',
          );
        }
      }
    }
    return BridgeResponse.success(true);
  }

  Future<BridgeResponse> _off(Map<String, dynamic> params) async {
    final event = params['event'] as String?;
    final callbackId = params['callbackId'] as String?;

    if (event == null || callbackId == null) {
      return BridgeResponse.error(-1, 'Event name and callbackId are required');
    }

    if (_eventListeners.containsKey(event)) {
      _eventListeners[event]!.remove(callbackId);
      if (_eventListeners[event]!.isEmpty) {
        _eventListeners.remove(event);
      }
    }
    return BridgeResponse.success(true);
  }

  @override
  List<String> getCapabilities() {
    return [
      'events.on',
      'events.once',
      'events.emit',
      'events.off',
    ];
  }
}