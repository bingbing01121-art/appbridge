import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bridge_response.dart';
import 'base_module.dart';
import 'ui_module.dart'; // Import UIModule

class AppStoreModule extends BaseModule {
  UIModule? _uiModule; // Make nullable and non-final

  AppStoreModule(this._uiModule); // Modify constructor

  void updateUIModule(UIModule uiModule) {
    _uiModule = uiModule;
  }

  @override
  Future<BridgeResponse> handleMethod(String action, Map<String, dynamic> params) async {
    print("AAAAAhandleMethod===action="+action+";params="+params.toString());
    if (Platform.isAndroid) {
      _uiModule?.toast(message: 'AppStore functionality is only available on iOS.'); // Show toast
      return BridgeResponse.error(-1, 'AppStore functionality is only available on iOS.');
    }
    switch (action) {
      case 'open':
        return await _open(params);
      case 'search':
        return await _search(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _open(Map<String, dynamic> params) async {
    final appId = params['appId'] as String?;
    if (appId == null) {
      return BridgeResponse.error(-1, 'appId is required');
    }

    final url = Uri.parse('https://apps.apple.com/app/id$appId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return BridgeResponse.success(null);
    } else {
      return BridgeResponse.error(-1, 'Could not launch $url');
    }
  }

  Future<BridgeResponse> _search(Map<String, dynamic> params) async {
    final query = params['query'] as String?;
    if (query == null) {
      return BridgeResponse.error(-1, 'query is required');
    }

    final url = Uri.parse('https://apps.apple.com/search?term=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return BridgeResponse.success(null);
    } else {
      return BridgeResponse.error(-1, 'Could not launch $url');
    }
  }
}
