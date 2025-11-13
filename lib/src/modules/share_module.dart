import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';

/// Share模块实现
class ShareModule extends BaseModule {
  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'open':
        return await _open(params);
      case 'copyLink':
        return await _copyLink(params);
      case 'get':
        return await _getClipboard();
      case 'set':
        return await _setClipboard(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _open(Map<String, dynamic> params) async {
    try {
      final text = params['text'] as String? ?? '';
      final url = params['url'] as String? ?? '';

      String shareText = text;
      if (url.isNotEmpty) {
        shareText = shareText.isEmpty ? url : '$shareText\n$url';
      }

      await SharePlus.instance.share(ShareParams(text: shareText));
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _copyLink(Map<String, dynamic> params) async {
    try {
      final url = params['url'] as String? ?? '';
      await Clipboard.setData(ClipboardData(text: url));
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null) {
        Fluttertoast.showToast(msg: clipboardData.text.toString());
        return BridgeResponse.success(clipboardData.text ?? '');
      } else {
        return BridgeResponse.success('');
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _setClipboard(Map<String, dynamic> params) async {
    try {
      final text = params['text'] as String?;
      if (text == null) {
        return BridgeResponse.error(-1, 'Text is required for clipboard.set');
      }
      await Clipboard.setData(ClipboardData(text: text));
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  @override
  List<String> getCapabilities() {
    return [
      'share.open',
      'share.copyLink',
      'clipboard.get',
      'clipboard.set',
    ];
  }
}
