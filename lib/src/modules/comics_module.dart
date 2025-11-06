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
    final id = params['id'] as String?;
    final url = params['url'] as String?;
    final title = params['title'] as String?;

    if (id == null && url == null) {
      return BridgeResponse.error(
          -1, 'Either id or url is required to open comics.');
    }

    if (url != null && url.isNotEmpty) {
      if (onLoadUrl != null) {
        await onLoadUrl!(url, title); // Pass title here
        return BridgeResponse.success(true);
      } else {
        return BridgeResponse.error(-1, 'Internal URL loading not configured.');
      }
    } else if (id != null) {
      return BridgeResponse.success({'message': 'Opened comics with ID: $id'});
    }

    return BridgeResponse.error(-1, 'Failed to open comics.');
  }
}
