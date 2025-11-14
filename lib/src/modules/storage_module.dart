import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';

/// Storage模块实现
class StorageModule extends BaseModule {
  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'get':
        return await _get(params);
      case 'set':
        return await _set(params);
      case 'remove':
        return await _remove(params);
      case 'clear':
        return await _clear(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _get(Map<String, dynamic> params) async {
    try {
      final key = params['key'] as String?;
      if (key == null) {
        return BridgeResponse.error(-1, 'Key is required');
      }

      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(key);

      return BridgeResponse.success({'key': key, 'value': value});
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _set(Map<String, dynamic> params) async {
    try {
      final key = params['key'] as String?;
      final value = params['value'];
      final ttlSec = params['ttlSec'] as int?;

      if (key == null) {
        return BridgeResponse.error(-1, 'Key is required');
      }

      final prefs = await SharedPreferences.getInstance();
      bool success = false;

      if (value is String) {
        success = await prefs.setString(key, value);
      } else if (value is int) {
        success = await prefs.setInt(key, value);
      } else if (value is double) {
        success = await prefs.setDouble(key, value);
      } else if (value is bool) {
        success = await prefs.setBool(key, value);
      } else if (value is List<String>) {
        success = await prefs.setStringList(key, value);
      } else {
        // 对于其他类型，转换为JSON字符串存储
        success = await prefs.setString(key, value.toString());
      }

      // 如果有TTL，存储过期时间
      if (ttlSec != null && success) {
        final expiryTime = DateTime.now()
            .add(Duration(seconds: ttlSec))
            .millisecondsSinceEpoch;
        await prefs.setInt('${key}_expiry', expiryTime);
      }

      return BridgeResponse.success(success);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _remove(Map<String, dynamic> params) async {
    try {
      final key = params['key'] as String?;
      if (key == null) {
        return BridgeResponse.error(-1, 'Key is required');
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(key);
      await prefs.remove('${key}_expiry'); // 同时删除过期时间

      return BridgeResponse.success(success);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _clear(Map<String, dynamic> params) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.clear();

      return BridgeResponse.success(success);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }
}
