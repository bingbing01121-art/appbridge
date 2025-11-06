import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bridge_response.dart';
import 'base_module.dart';
import 'ui_module.dart'; // Import UIModule

class DeepLinkModule extends BaseModule {
  UIModule? _uiModule; // Make nullable and non-final
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkModule(this._uiModule) {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      // Handle incoming deep links
      _uiModule?.toast(message: 'Received deep link: $uri');
    });
  }

  void updateUIModule(UIModule uiModule) {
    _uiModule = uiModule;
  }

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    debugPrint("DeepLinkModule-action==$action;params==$params");
    switch (action) {
      case 'open':
        return await _open(params);
      case 'parse':
        return await _parse(
          params,
        ); // Placeholder for parsing initial deep link
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _open(Map<String, dynamic> params) async {
    final urlString = params['url'] as String?;
    if (urlString == null) {
      _uiModule?.toast(
        message: 'URL is required for deep link open.',
      ); // Add toast
      return BridgeResponse.error(-1, 'url is required');
    }

    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return BridgeResponse.success({'parsedLink': urlString});
    } else {
      _uiModule?.toast(message: 'Could not launch $urlString.'); // Add toast
      return BridgeResponse.error(-1, 'Could not launch $url');
    }
  }

  Future<BridgeResponse> _parse(Map<String, dynamic> params) async {
    final urlString = params['url'] as String?;
    int? startIndex1 = urlString?.lastIndexOf('url=');
    if (startIndex1 != -1) {
      String? result1 = urlString?.substring(
        startIndex1! + 4,
        urlString.length - 1,
      );
      return BridgeResponse.success({'parsedLink': result1});
    }
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      return BridgeResponse.success({'parsedLink': urlString});
    } else {
      return BridgeResponse.success({'parsedLink': null});
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
