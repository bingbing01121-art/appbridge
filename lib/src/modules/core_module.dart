import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter_pinned_shortcut_plus/flutter_pinned_shortcut_plus.dart';

import '../models/bridge_response.dart';
import '../models/environment_info.dart';
import '../models/version_info.dart';
import 'package:quick_actions/quick_actions.dart';
import 'base_module.dart';

/// Core模块实现
class CoreModule extends BaseModule {
  final MethodChannel _platform;

  CoreModule(this._platform);

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'getVersion':
        return await _getVersion();
      case 'getEnv':
        return await _getEnv();
      case 'ready':
        return await _ready();
      case 'has':
        return await _has(params['path'] as String? ?? '');
      case 'getCapabilities':
        return await _getCapabilities();
      case 'setVpn':
        return await _setVpn(params);
      case 'addShortcuts':
        return await _addShortcuts(params);
      case 'appIcon':
        return await _appIcon(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  /// 获取版本信息
  Future<BridgeResponse> _getVersion() async {
    try {
      // Load app package info
      final packageInfo = await PackageInfo.fromPlatform();

      // Load SDK package info from assets
      final sdkPackageJsonString = await rootBundle.loadString(
        'packages/appbridge/assets/sdk_package.json',
      );
      final sdkPackageJson = json.decode(sdkPackageJsonString);
      final sdkVersion = sdkPackageJson['version'] as String? ?? '0.0.0';

      final deviceInfo = DeviceInfoPlugin();

      String platform = 'Unknown';
      String systemType = 'Unknown';
      String osVersion = 'Unknown';
      String manufacturer = 'Unknown';
      String deviceModel = 'Unknown';
      String brand = 'Unknown';
      int? sdkInt;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platform = 'Android';
        systemType = 'Android';
        osVersion = 'Android ${androidInfo.version.release}';
        manufacturer = androidInfo.manufacturer;
        deviceModel = androidInfo.model;
        brand = androidInfo.brand;
        sdkInt = androidInfo.version.sdkInt;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platform = 'iOS';
        systemType = 'iOS';
        osVersion = 'iOS ${iosInfo.systemVersion}';
        manufacturer = 'Apple';
        deviceModel = iosInfo.model;
        brand = 'Apple';
      }

      final versionInfo = VersionInfo(
        bridgeVersion: sdkVersion,
        appId: packageInfo.packageName,
        appName: packageInfo.appName,
        packageName: packageInfo.packageName,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platform: platform,
        systemType: systemType,
        osVersion: osVersion,
        manufacturer: manufacturer,
        deviceModel: deviceModel,
        brand: brand,
        sdkInt: sdkInt,
        channel: 'AppStore',
        region: Platform.localeName.split('_').last,
        lang: Platform.localeName.split('_').first,
        isDebug: false,
      );

      return BridgeResponse.success(versionInfo.toJson());
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  /// 获取环境信息
  Future<BridgeResponse> _getEnv() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      String networkType = 'none';
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        networkType = 'wifi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        networkType = '4g';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        networkType = 'wifi'; // Ethernet can be considered similar to wifi for network type
      } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
        networkType = 'bluetooth';
      } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
        networkType = 'vpn';
      } else if (connectivityResult.contains(ConnectivityResult.other)) {
        networkType = 'other';
      } else if (connectivityResult.contains(ConnectivityResult.none)) {
        networkType = 'none';
      }

      final envInfo = EnvironmentInfo(
        env: 'prod',
        channel: 'AppStore',
        region: Platform.localeName.split('_').last,
        lang: Platform.localeName.split('_').first,
        timezone: DateTime.now().timeZoneName,
        networkType: networkType,
        isDebug: false,
        isEmulator: false,
        buildType: 'release',
        commitHash: null,
        featureFlags: [],
        appId: packageInfo.packageName,
        foreground: true,
        powerSave: false,
        vpnEnabled: false,
        networkRestricted: false,
      );
      debugPrint("CoreModule获取环境信息返回==${envInfo.toJson()}");
      return BridgeResponse.success(envInfo.toJson());
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  /// 准备就绪
  Future<BridgeResponse> _ready() async {
    return BridgeResponse.success(true);
  }

  /// 检查方法是否存在
  Future<BridgeResponse> _has(String path) async {
    // 这里可以根据实际需要检查方法是否存在
    final availableMethods = [
      'core.getVersion',
      'core.getEnv',
      'core.ready',
      'core.has',
      'core.getCapabilities',
      'events.on',
      'events.once',
      'events.emit',
      'app.getStatus',
      'ui.toast',
      'ui.alert',
      'ui.confirm',
      'storage.get',
      'storage.set',
      'device.getInfo',
      'permission.check',
      'permission.request',
    ];

    return BridgeResponse.success(availableMethods.contains(path));
  }

  /// 获取可用方法列表
  Future<BridgeResponse> _getCapabilities() async {
    debugPrint("_getCapabilities--进入方法列表");
    final capabilities = [
      'core.getVersion',
      'core.getEnv',
      'core.ready',
      'core.has',
      'core.getCapabilities',
      'events.on',
      'events.once',
      'events.emit',
      'app.getStatus',
      'ui.toast',
      'ui.alert',
      'ui.confirm',
      'storage.get',
      'storage.set',
      'device.getInfo',
      'permission.check',
      'permission.request',
    ];

    return BridgeResponse.success(capabilities);
  }

  /// 设置VPN
  Future<BridgeResponse> _setVpn(Map<String, dynamic> params) async {
    try {
      final bool on = params['on'] as bool? ?? false;
      final Map<String, dynamic>? config =
          params['config'] as Map<String, dynamic>?;

      if (on && config == null) {
        return BridgeResponse.error(
          -1,
          'VPN configuration is required when turning on VPN',
        );
      }

      final result = await _platform.invokeMethod('setVpn', {
        'on': on,
        'config': config,
      });
      return BridgeResponse.success(result);
    } on PlatformException catch (e) {
      int errorCode;
      try {
        errorCode = int.parse(e.code);
      } catch (_) {
        errorCode = -1; // Default error code if e.code is not a valid integer
      }
      return BridgeResponse.error(
        errorCode,
        e.message ?? 'Unknown PlatformException',
      );
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  /// 添加快捷方式
  Future<BridgeResponse> _addShortcuts(Map<String, dynamic> params) async {
    if (Platform.isAndroid) {
      return await _addPinnedShortcut(params);
    } else if (Platform.isIOS) {
      return await _addQuickAction(params);
    } else {
      return BridgeResponse.error(-1, 'Unsupported platform');
    }
  }

  /// 添加桌面快捷方式 (Android only)
  Future<BridgeResponse> _addPinnedShortcut(Map<String, dynamic> params) async {
    try {
      final title = params['title'] as String? ?? 'Shortcut';
      final url = params['url'] as String? ?? '';

      if (url.isEmpty) {
        return BridgeResponse.error(-1, 'URL is required for a shortcut');
      }

      await FlutterPinnedShortcut().createPinnedShortcut(
        id: url,
        label: title,
        action: url, // Add action parameter
        iconAssetName: 'assets/icon_h5sdk_new.png', // Placeholder icon
      );

      return BridgeResponse.success(true);
    } catch (e) {
      debugPrint(e.toString());
      return BridgeResponse.error(
        -1,
        'Failed to add pinned shortcut: ${e.toString()}',
      );
    }
  }

  /// 添加应用内快捷方式 (iOS)
  Future<BridgeResponse> _addQuickAction(Map<String, dynamic> params) async {
    try {
      const quickActions = QuickActions();
      final title = params['title'] as String? ?? 'Shortcut';
      final url = params['url'] as String? ?? '';

      if (url.isEmpty) {
        return BridgeResponse.error(-1, 'URL is required for a shortcut');
      }

      await quickActions.setShortcutItems([
        ShortcutItem(
          type: url, // Use the URL as the unique identifier
          localizedTitle: '$title快捷方式',
          icon: 'ic_launcher', // Placeholder icon, user needs to add a real one
        ),
      ]);

      return BridgeResponse.success(true);
    } catch (e) {
      debugPrint(e.toString());
      return BridgeResponse.error(
        -1,
        'Failed to add shortcut: ${e.toString()}',
      );
    }
  }

  /// 切换应用图标
  Future<BridgeResponse> _appIcon(Map<String, dynamic> params) async {
    debugPrint("AAAAAA切换应用图标--_appIcon");
    try {
      final styleId = params['styleId'] as String?;
      if (styleId == null) {
        return BridgeResponse.error(-1, 'styleId is required for appIcon');
      }
      final result = await _platform.invokeMethod('appIcon', {
        'styleId': styleId,
      });
      return BridgeResponse.success(result);
    } on PlatformException catch (e) {
      int errorCode = -1;
      try {
        errorCode = int.parse(e.code);
      } catch (_) {
        // If e.code is not a valid integer, use -1
        errorCode = -1;
      }
      return BridgeResponse.error(
          errorCode, e.message ?? 'Unknown PlatformException');
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }
}
