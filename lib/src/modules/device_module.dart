import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'base_module.dart';
import '../models/bridge_response.dart';
import '../models/device_info.dart';

/// Device模块实现
class DeviceModule extends BaseModule {
  final MethodChannel _platform;

  DeviceModule(this._platform);

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'getIds':
        return await _getIds();
      case 'getInfo':
        return await _getInfo();
      case 'getBattery':
        return await _getBattery();
      case 'getStorageInfo':
        return await _getStorageInfo();
      case 'getMemoryInfo':
        return await _getMemoryInfo();
      case 'getCpuInfo':
        return await _getCpuInfo();
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _getIds() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      }

      final ids = {
        'deviceId': deviceId,
        'installationId': deviceId, // 简化实现
      };

      return BridgeResponse.success(ids);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String platform = 'Unknown';
      String systemType = 'Unknown';
      String osVersion = 'Unknown';
      String manufacturer = 'Unknown';
      String brand = 'Unknown';
      String model = 'Unknown';
      int? sdkInt;
      int screenWidth = 0;
      int screenHeight = 0;
      double pixelRatio = 1.0;
      int dpi = 160;
      int physicalWidth = 0;
      int physicalHeight = 0;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platform = 'Android';
        systemType = 'Android';
        osVersion = 'Android ${androidInfo.version.release}';
        manufacturer = androidInfo.manufacturer;
        brand = androidInfo.brand;
        model = androidInfo.model;
        sdkInt = androidInfo.version.sdkInt;
        screenWidth = 0; // Not directly available from AndroidDeviceInfo
        screenHeight = 0; // Not directly available from AndroidDeviceInfo
        pixelRatio = 1.0; // Default value
        dpi = 160; // Default value
        physicalWidth = 0; // Not directly available from AndroidDeviceInfo
        physicalHeight = 0; // Not directly available from AndroidDeviceInfo
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platform = 'iOS';
        systemType = 'iOS';
        osVersion = 'iOS ${iosInfo.systemVersion}';
        manufacturer = 'Apple';
        brand = 'Apple';
        model = iosInfo.model;
        screenWidth = 390; // 简化实现
        screenHeight = 844; // 简化实现
        pixelRatio = 3.0; // 简化实现
        dpi = 460; // 简化实现
        physicalWidth = 1170; // 简化实现
        physicalHeight = 2532; // 简化实现
      }

      final deviceInfoModel = DeviceInfo(
        platform: platform,
        systemType: systemType,
        osVersion: osVersion,
        manufacturer: manufacturer,
        brand: brand,
        model: model,
        appId: packageInfo.packageName,
        packageName: packageInfo.packageName,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        sdkInt: sdkInt,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        pixelRatio: pixelRatio,
        dpi: dpi,
        physicalWidth: physicalWidth,
        physicalHeight: physicalHeight,
        locale: Platform.localeName.split('_').first,
        region: Platform.localeName.split('_').last,
        timezone: DateTime.now().timeZoneName,
      );

      return BridgeResponse.success(deviceInfoModel.toJson());
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getBattery() async {
    try {
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      final batteryState = await battery.batteryState;

      final batteryInfo = {
        'level': batteryLevel / 100.0,
        'charging': batteryState == BatteryState.charging,
        'powerSave': false, // 简化实现
      };

      return BridgeResponse.success(batteryInfo);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getStorageInfo() async {
    try {
      final Map<dynamic, dynamic> result =
          await _platform.invokeMethod('getStorageInfo');
      final totalStorage = result['totalStorage'] as int;
      final availableStorage = result['availableStorage'] as int;

      final storageInfo = {
        'total': (totalStorage / (1024 * 1024)).round(), // Convert to MB
        'free': (availableStorage / (1024 * 1024)).round(), // Convert to MB
        'unit': 'MB',
      };

      return BridgeResponse.success(storageInfo);
    } on PlatformException catch (e) {
      return BridgeResponse.error(
          -1, "Failed to get storage info: '${e.message}'.");
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getMemoryInfo() async {
    try {
      final Map<dynamic, dynamic> result =
          await _platform.invokeMethod('getMemoryInfo');
      final totalMemory = result['totalMemory'] as int;
      final availableMemory = result['availableMemory'] as int;

      final memoryInfo = {
        'total': (totalMemory / (1024 * 1024)).round(), // Convert to MB
        'free': (availableMemory / (1024 * 1024)).round(), // Convert to MB
        'lowMemory':
            false, // Native Android doesn't directly provide this in MemoryInfo
        'unit': 'MB',
      };

      return BridgeResponse.success(memoryInfo);
    } on PlatformException catch (e) {
      return BridgeResponse.error(
          -1, "Failed to get memory info: '${e.message}'.");
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getCpuInfo() async {
    try {
      final Map<dynamic, dynamic> result =
          await _platform.invokeMethod('getCpuInfo');
      final cores = result['cores'] as int;
      final arch = result['arch'] as String;
      final frequency = result['frequency'] as String;

      final cpuInfo = {
        'cores': cores,
        'arch': arch,
        'frequency': frequency,
      };

      return BridgeResponse.success(cpuInfo);
    } on PlatformException catch (e) {
      return BridgeResponse.error(
          -1, "Failed to get CPU info: '${e.message}'.");
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }
}
