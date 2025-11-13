import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for MethodChannel
import '../models/bridge_response.dart';
import 'base_module.dart';
import 'ui_module.dart';

class DeepLinkModule extends BaseModule {
  final MethodChannel _platformChannel;

  DeepLinkModule(UIModule? uiModule) : _platformChannel = const MethodChannel('com.example.appbridge_example/deeplink');

  void updateUIModule(UIModule uiModule) {}

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    debugPrint("DeepLinkModule-action==$action;params==$params");
    try {
      switch (action) {
        case 'open':
          final url = params['url'] as String?;
          if (url != null) {
            final result = await _platformChannel.invokeMethod('openDeepLink', {'url': url});
            return BridgeResponse.success(result);
          }
          return BridgeResponse.error(-1, 'URL is null');
        case 'parse':
          final result = await _platformChannel.invokeMethod('parseDeepLink');
          return BridgeResponse.success(result);
        default:
          return BridgeResponse.error(-1, 'Unknown action: $action');
      }
    } on PlatformException catch (e) {
      return BridgeResponse.error(int.parse(e.code), e.message ?? 'Unknown error');
    }
  }

  @override
  List<String> getCapabilities() {
    return [
      'deeplink.open',
      'deeplink.parse',
    ];
  }
}
