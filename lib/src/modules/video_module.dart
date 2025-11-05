import '../../appbridge.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';
import 'package:flutter/material.dart';
import '../video_player_page.dart';

typedef LoadUrlCallback = Future<void> Function(String url, String? title);

class VideoModule extends BaseModule {
  BuildContext? _context;
  LoadUrlCallback? onLoadUrl;

  VideoModule(this._context, {this.onLoadUrl});

  void updateContext(BuildContext? context) {
    _context = context;
  }

  @override
  Future<BridgeResponse> handleMethod(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'open':
        return await _openVideo(params);
      // TODO: Implement other video player actions and events
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _openVideo(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    final url = params['url'] as String?;
    final title = params['title'] as String?;

    if (id == null && url == null) {
      return BridgeResponse.error(-1, 'Either id or url is required to open video.');
    }

    if (url != null && url.isNotEmpty) {
      if (onLoadUrl != null) {
        await onLoadUrl!(url, title); // Pass title here
        return BridgeResponse.success(true);
      } else {
        return BridgeResponse.error(-1, 'Internal URL loading not configured.');
      }
    } else if (id != null) {
      // If only an ID is provided, we could potentially fetch the URL, but for now, we just acknowledge.
      return BridgeResponse.success({'message': 'Received video ID: $id. URL needed to play.'});
    }

    return BridgeResponse.error(-1, 'Failed to open video.');
  }
}
