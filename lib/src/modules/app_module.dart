import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Import MethodChannel
import 'package:in_app_update/in_app_update.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';

/// App模块实现
class AppModule extends BaseModule {
  final MethodChannel _platform;
  AppUpdateInfo? _updateInfo;

  AppModule(this._platform);

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'getStatus':
        return await _getStatus();
      case 'openSettings':
        return await _openSettings(params);
      case 'exit':
        return await _exit();
      case 'minimize':
        return await _minimize();
      case 'update.check':
        return await _checkUpdate();
      case 'update':
        if (context == null) {
          return BridgeResponse.error(
              -1, 'BuildContext is required for app update.');
        }
        if (kDebugMode) {
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            _showSimulatedUpdateDialog(context);
          }
          return BridgeResponse.success(true);
        }
        return await _applyUpdate(context);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _getStatus() async {
    try {
      final status = {
        'foreground': true,
        'powerSave': false,
        'vpnEnabled': false,
        'networkRestricted': false,
      };
      return BridgeResponse.success(status);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _openSettings(Map<String, dynamic> params) async {
    try {
      await openAppSettings();
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _exit() async {
    try {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
        return BridgeResponse.success(true);
      } else if (Platform.isIOS) {
        return BridgeResponse.error(
            -1, 'iOS系统不支持退出。');
      } else {
        // Handle other platforms if necessary, or default to pop
        SystemNavigator.pop();
        return BridgeResponse.success(true);
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _minimize() async {
    try {
      if (Platform.isAndroid) {
        await _platform.invokeMethod('minimizeApp');
        return BridgeResponse.success(true);
      } else {
        return BridgeResponse.error(
            -1, 'iOS系统不支持应用最小化功能。');
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _checkUpdate() async {
    if (kDebugMode) {
      return BridgeResponse.success({
        'hasUpdate': true,
        'version': '2.0.0-mock',
        'message': 'This is a simulated update response.',
      });
    }
    if (Platform.isAndroid) {
      try {
        final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
        _updateInfo = updateInfo;
        return BridgeResponse.success({
          'hasUpdate': updateInfo.updateAvailability ==
              UpdateAvailability.updateAvailable,
          'version': updateInfo.availableVersionCode?.toString() ?? '',
        });
      } catch (e) {
        return BridgeResponse.error(-1, e.toString());
      }
    } else {
      return BridgeResponse.success({
        'hasUpdate': false,
        'message': 'In-app update is only available for Android.'
      });
    }
  }

  Future<BridgeResponse> _applyUpdate(BuildContext context) async {
    if (!context.mounted) {
      return BridgeResponse.error(-1, 'Context not mounted.');
    }
    if (Platform.isAndroid) {
      if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        try {
          await InAppUpdate.performImmediateUpdate();
          return BridgeResponse.success(true);
        } catch (e) {
          return BridgeResponse.error(-1, e.toString());
        }
      } else {
        return BridgeResponse.error(0, 'No update available to apply.');
      }
    } else {
      return BridgeResponse.error(
          -1, 'In-app update is only available for Android.');
    }
  }

  void _showSimulatedUpdateDialog(BuildContext context) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: _SimulatedUpdateDialogContent(rootContext: context),
        );
      },
    );
  }
}

class _SimulatedUpdateDialogContent extends StatefulWidget {
  final BuildContext rootContext;
  const _SimulatedUpdateDialogContent({required this.rootContext});

  @override
  _SimulatedUpdateDialogContentState createState() =>
      _SimulatedUpdateDialogContentState();
}

class _SimulatedUpdateDialogContentState
    extends State<_SimulatedUpdateDialogContent> {
  bool _isDownloading = false;
  double _progress = 0.0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.05;
        if (_progress >= 1.0) {
          _timer?.cancel();
          _progress = 1.0;
          // Close the dialog and show snackbar after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop();
              if (widget.rootContext.mounted) { // Add mounted check for rootContext
                ScaffoldMessenger.of(widget.rootContext).showSnackBar(
                  const SnackBar(content: Text('更新成功！')),
                );
              } // Added missing closing brace
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!_isDownloading)
            _buildInitialContent()
          else
            _buildDownloadingContent(),
        ],
      ),
    );
  }

  Widget _buildInitialContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.system_update_rounded,
          color: Theme.of(context).primaryColor,
          size: 50.0,
        ),
        const SizedBox(height: 20),
        const Text(
          '发现新版本 V1.0.2',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            color: Colors.blue, // Changed to blue
          ),
        ),
        const SizedBox(height: 15),
        Text(
          '部分功能bug修复，我们努力进行了更新。\n建议您立即升级，体验全新功能！',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blue, // Changed to blue
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 20),
        _buildUpdateLog(),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            TextButton(
              child: const Text('以后再说',
                  style: TextStyle(
                      fontSize: 16, color: Colors.blue)), // Changed to blue
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Changed to blue
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: _startDownload,
              child: const Text('立即更新', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '正在下载更新...',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Colors.blue, // Changed to blue
          ),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: _progress,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
          color: Colors.blue, // Changed to blue
          backgroundColor:
              Colors.blue.withAlpha((255 * 0.2).round()), // Changed to blue
        ),
        const SizedBox(height: 10),
        Text('${(_progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: Colors.blue)), // Changed to blue
        const SizedBox(height: 20),
        const Text(
          '请保持应用在前台，不要锁屏',
          style: TextStyle(
            color: Colors.blue, // Changed to blue
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateLog() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
      ),
      constraints: const BoxConstraints(
        maxHeight: 120.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('更新日志:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)), // Changed to blue
            SizedBox(height: 8),
            Text('  • [新增] 1.0.0基础版基于安卓实现基本功能',
                style: TextStyle(color: Colors.blue)), // Changed to blue
            SizedBox(height: 4),
            Text('  • [优化] 1.0.1处理添加快捷方式及修改图标功能为插件通信，具体实现由消费端实现和修复ios编译兼容',
                style: TextStyle(color: Colors.blue)), // Changed to blue
          ],
        ),
      ),
    );
  }
}
