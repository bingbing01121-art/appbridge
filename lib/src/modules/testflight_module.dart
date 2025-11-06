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

  Future<BridgeResponse> _open(Map<String, dynamic> params) async {
    final urlString = params['url'] as String?;
    if (urlString == null) {
      _uiModule?.toast(
          message: 'textURL is required for TestFlight open.'); // Add toast
      return BridgeResponse.error(-1, 'url is required');
    }

    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return BridgeResponse.success(null);
    } else {
      _uiModule?.toast(
          message: 'textCould not launch $urlString.'); // Add toast
      return BridgeResponse.error(-1, 'Could not launch $url');
    }
  }
}
