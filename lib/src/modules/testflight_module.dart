import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bridge_response.dart';
import 'base_module.dart';
import 'dart:io';
import 'ui_module.dart'; // Import UIModule

class TestFlightModule extends BaseModule {
  UIModule? _uiModule; // Make nullable

  TestFlightModule(this._uiModule); // Modify constructor

  void updateUIModule(UIModule uiModule) {
    _uiModule = uiModule;
  }

  Future<BridgeResponse> _open(Map<String, dynamic> params) async {
    final url = params['url'] as String?;
    if (url == null || url.isEmpty) {
      return BridgeResponse.error(-1, 'URL is required to open TestFlight.');
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return BridgeResponse.success(true);
    } else {
      return BridgeResponse.error(-1, 'Could not launch TestFlight URL: $url');
    }
  }

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    if (Platform.isAndroid) {
      _uiModule?.toast(
          message:
              'textTestFlight functionality is only available on iOS.'); // Show toast
      return BridgeResponse.error(
          -1, 'TestFlight functionality is only available on iOS.');
    }
    switch (action) {
      case 'open':
        return await _open(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  @override
  List<String> getCapabilities() {
    return [
      'testflight.open',
    ];
  }
}
