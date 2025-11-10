// import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // Commented out
import '../models/bridge_response.dart';
import 'base_module.dart';
import 'ui_module.dart'; // Import UIModule

// Dummy DeepLinkModule to allow compilation without app_links
class DeepLinkModule extends BaseModule {
  DeepLinkModule(UIModule? uiModule); // Constructor for compatibility

  void updateUIModule(UIModule uiModule) {} // Dummy method

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    debugPrint("DeepLinkModule-action==$action;params==$params");
    return BridgeResponse.error(-1, 'DeepLink functionality is not available (app_links removed).');
  }

  void dispose() {} // Dummy method
}
