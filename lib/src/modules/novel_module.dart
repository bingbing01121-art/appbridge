import '../../appbridge.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';
import 'package:flutter/material.dart';

typedef LoadUrlCallback = Future<void> Function(String url, String? title);

class NovelModule extends BaseModule {
  BuildContext? _context;
  LoadUrlCallback? onLoadUrl;

  NovelModule(this._context, {this.onLoadUrl});

  void updateContext(BuildContext? context) {
    _context = context;
  }

  @override
  Future<BridgeResponse> handleMethod(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'open':
        return await _openNovel(params);
      // TODO: Implement other novel reader actions and events
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _openNovel(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    final url = params['url'] as String?;
    final title = params['title'] as String?;

    if (id == null && url == null) {
      return BridgeResponse.error(-1, 'Either id or url is required to open novel.');
    }

    if (url != null && url.isNotEmpty) {
      if (onLoadUrl != null) {
        await onLoadUrl!(url, title); // Pass title here
        return BridgeResponse.success(true);
      } else {
        return BridgeResponse.error(-1, 'Internal URL loading not configured.');
      }
    } else if (id != null) {
      return BridgeResponse.success({'message': 'Opened novel with ID: $id'});
    }

    return BridgeResponse.error(-1, 'Failed to open novel.');
  }
}
