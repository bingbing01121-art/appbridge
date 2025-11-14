import 'package:flutter/material.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';

typedef LoadUrlCallback = Future<void> Function(String url, String? title);

class PostModule extends BaseModule {
  LoadUrlCallback? onLoadUrl;

  PostModule({this.onLoadUrl});

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'open':
        return await _openPost(params);
      // TODO: Implement other post actions and events
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _openPost(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    final url = params['url'] as String?;
    final title = params['title'] as String?;

    if (id == null && url == null) {
      return BridgeResponse.error(
          -1, 'Either id or url is required to open post.');
    }

    if (url != null && url.isNotEmpty) {
      if (onLoadUrl != null) {
        await onLoadUrl!(url, title); // Pass title here
        return BridgeResponse.success(true);
      } else {
        return BridgeResponse.error(-1, 'Internal URL loading not configured.');
      }
    } else if (id != null) {
      return BridgeResponse.success({'message': 'Opened post with ID: $id'});
    }

    return BridgeResponse.error(-1, 'Failed to open post.');
  }
}
