import 'package:flutter/material.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';

typedef LoadUrlCallback = Future<void> Function(String url, String? title);

class ComicsModule extends BaseModule {
  LoadUrlCallback? onLoadUrl;

  ComicsModule({this.onLoadUrl});

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'open':
        return await _openComics(params);
      // TODO: Implement other comics reader actions and events
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _openComics(Map<String, dynamic> params) async {
    final url = params['url'] as String?;
    final title = params['title'] as String?;

    if (url == null || url.isEmpty) {
      return BridgeResponse.error(-1, 'Comics URL is required.');
    }

    if (onLoadUrl != null) {
      await onLoadUrl!(url, title);
      return BridgeResponse.success(true);
    } else {
      // Fallback if onLoadUrl is not set, e.g., launch with url_launcher
      // For now, just return an error or a placeholder
      return BridgeResponse.error(-1, 'Comics reader not configured (onLoadUrl is null).');
    }
  }

  @override
  List<String> getCapabilities() {
    return [
      'comics.open',
      // TODO: Add other comics reader capabilities as they are implemented
    ];
  }
}
