import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';

/// Permission模块实现
class PermissionModule extends BaseModule {
  PermissionModule();

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'check':
        return await _check(params);
      case 'request':
        return await _request(params);
      case 'ensure':
        return await _ensure(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _check(Map<String, dynamic> params) async {
    try {
      final name = params['name'] as String?;
      if (name == null) {
        return BridgeResponse.error(-1, 'Permission name is required');
      }
      final permission = _getPermission(name);
      final status = await permission.status;
      return BridgeResponse.success(status.isGranted);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _request(Map<String, dynamic> params) async {
    try {
      final name = params['name'] as String?;
      if (name == null) {
        return BridgeResponse.error(-1, 'Permission name is required');
      }

      final permission = _getPermission(name);
      final status = await permission.request();

      return BridgeResponse.success(status.isGranted);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _ensure(Map<String, dynamic> params) async {
    try {
      final name = params['name'] as String?;
      if (name == null) {
        return BridgeResponse.error(-1, 'Permission name is required');
      }

      final permission = _getPermission(name);
      debugPrint('PermissionModule: Checking status for $name');
      PermissionStatus status = await permission.status;
      debugPrint('PermissionModule: Initial status for $name: $status');

      if (name == 'notifications') {
        if (status.isGranted) {
          // NotificationsModule will handle showing the notification
          return BridgeResponse.success(true);
        } else if (status.isDenied || status.isPermanentlyDenied) {
          openAppSettings(); // Open app settings for user to grant permission
          return BridgeResponse.success(false);
        } else {
          // isUndetermined
          status = await permission.request();
          if (status.isGranted) {
            // NotificationsModule will handle showing the notification
            return BridgeResponse.success(true);
          } else {
            openAppSettings();
            return BridgeResponse.success(false);
          }
        }
      } else if (name == 'camera') {
        if (!status.isGranted) {
          debugPrint('PermissionModule: Camera not granted, requesting...');
          status = await permission.request();
          debugPrint('PermissionModule: Status after request for camera: $status');
        }
        if (status.isGranted) {
          debugPrint('PermissionModule: Camera granted, attempting to pick image...');
          try {
            final ImagePicker picker = ImagePicker();
            final XFile? image =
                await picker.pickImage(source: ImageSource.camera);
            if (image != null) {
              debugPrint('PermissionModule: Picked image path: ${image.path}');
              return BridgeResponse.success({'path': image.path});
            } else {
              debugPrint('PermissionModule: Image picking cancelled or failed.');
              return BridgeResponse.success({'path': null, 'cancelled': true});
            }
          } catch (e) {
            debugPrint('PermissionModule: Error picking image: $e');
            return BridgeResponse.error(-1, 'Error picking image: $e');
          }
        } else {
          debugPrint('PermissionModule: Camera permission not granted after request. Opening app settings.');
          await openAppSettings(); // Open app settings if permission is not granted
          return BridgeResponse.success(false);
        }
      } else {
        if (!status.isGranted) {
          debugPrint('PermissionModule: Other permission not granted, requesting...');
          status = await permission.request();
          debugPrint('PermissionModule: Status after request for other permission: $status');
        }
        return BridgeResponse.success(status.isGranted);
      }
    } catch (e) {
      debugPrint('PermissionModule: Top-level error in _ensure: $e');
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Permission _getPermission(String name) {
    switch (name) {
      case 'camera':
        return Permission.camera;
      case 'photo':
        return Permission.photos;
      case 'mic':
        return Permission.microphone;
      case 'location':
        return Permission.location;
      case 'bluetooth':
        return Permission.bluetooth;
      case 'notifications':
        return Permission.notification;
      case 'storage':
        return Permission.storage;
      case 'contacts':
        return Permission.contacts;
      case 'sms':
        return Permission.sms;
      case 'phone':
        return Permission.phone;
      default:
        throw Exception('Unknown permission: $name');
    }
  }
}
