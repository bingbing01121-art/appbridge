import 'package:flutter/material.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart' as FFmpegKitPackage;
import 'package:ffmpeg_kit_flutter_new/return_code.dart' as FFmpegReturnCodePackage;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart' as FFmpegKitConfigPackage;

import '../models/bridge_response.dart';
import 'base_module.dart';

/// Download模块实现
typedef EventEmitter = Future<void> Function(String event, dynamic payload);

class DownloadModule extends BaseModule {
  final MethodChannel _methodChannel;
  final EventEmitter eventEmitter;
  static const String _defaultDownloadDirPathKey = 'defaultDownloadDirPath';

  DownloadModule(this._methodChannel, this.eventEmitter);

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'start':
        return await _startDownload(params);
      case 'pause':
        return await _pauseDownload(params);
      case 'resume':
        return await _resumeDownload(params);
      case 'cancel':
        return await _cancelDownload(params);
      case 'status':
        return await _getDownloadStatus(params);
      case 'list':
        return await _getDownloadList();
      case 'm3u8':
        return await _downloadM3u8(params);
      case 'getDefaultDir':
        return await _getDefaultDir();
      case 'setDefaultDir':
        return await _setDefaultDir(params);
      case 'getFilePath':
        return await _getFilePath(params);
      case 'download':
        return await _downloadApk(params);
      case 'install':
        return await _installApk(params);
      case 'open':
        return await _openApk(params);
      case 'isInstalled':
        return await _isApkInstalled(params);
      case 'getSize':
        return await _getCacheSize();
      case 'clear':
        return await _clearCache(params);
      case 'getThumbnail':
        return await _getThumbnailForM3u8(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _startDownload(Map<String, dynamic> params) async {
    try {
      final url = params['url'] as String?;
      final id = params['id'] as String? ??
          'download_${DateTime.now().millisecondsSinceEpoch}';
      final fileName =
          params['fileName'] as String? ?? '$id.apk'; // 扩展名需要从下载链接提取

      if (url == null) {
        return BridgeResponse.error(-1, 'URL is required');
      }

      final prefs = await SharedPreferences.getInstance();
      final defaultDownloadDirPath =
          prefs.getString(_defaultDownloadDirPathKey);

      String savedDir;
      if (defaultDownloadDirPath != null && defaultDownloadDirPath.isNotEmpty) {
        savedDir = defaultDownloadDirPath;
      } else {
        final downloadDir =
            await getTemporaryDirectory(); // Use temporary directory
        savedDir = downloadDir.path;
      }

      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: fileName,
        showNotification:
            false, // show download progress in status bar (for Android)
        openFileFromNotification:
            false, // click on notification to open file (for Android)
      ); // <--- Added missing closing parenthesis and semicolon
      if (taskId != null) {
        eventEmitter('download.started', {
          'id': taskId,
          'path': '$savedDir/$fileName',
          'fileName': fileName, // Pass fileName for UI
        });
        return BridgeResponse.success({
          'id': taskId,
          'path': '$savedDir/$fileName',
        });
      } else {
        return BridgeResponse.error(-1, 'Failed to enqueue download');
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _pauseDownload(Map<String, dynamic> params) async {
    debugPrint('[_pauseDownload] Received params: $params');
    try {
      final id = params['id'] as String?;
      if (id == null) {
        debugPrint('[_pauseDownload] Error: Download ID is required');
        return BridgeResponse.error(-1, 'Download ID is required');
      }
      debugPrint('[_pauseDownload] Attempting to pause download with ID: $id');
      await FlutterDownloader.pause(taskId: id);
      debugPrint('[_pauseDownload] FlutterDownloader.pause completed for ID: $id');
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _resumeDownload(Map<String, dynamic> params) async {
    debugPrint('[_resumeDownload] Received params: $params');
    try {
      final id = params['id'] as String?;
      if (id == null) {
        debugPrint('[_resumeDownload] Error: Download ID is required');
        return BridgeResponse.error(-1, 'Download ID is required');
      }
      debugPrint('[_resumeDownload] Attempting to resume download with ID: $id');
      final newTaskId = await FlutterDownloader.resume(taskId: id);
      debugPrint('[_resumeDownload] FlutterDownloader.resume returned newTaskId: $newTaskId');
      if (newTaskId != null) {
        // Fetch the actual status and progress after resuming
        final tasks = await FlutterDownloader.loadTasksWithRawQuery(
            query: 'SELECT * FROM task WHERE task_id="$newTaskId"');
        String statusString = 'unknown';
        int currentProgress = 0;
        if (tasks != null && tasks.isNotEmpty) {
          final task = tasks.first;
          switch (task.status) {
            case DownloadTaskStatus.enqueued:
              statusString = 'enqueued';
              break;
            case DownloadTaskStatus.running:
              statusString = 'downloading';
              break;
            case DownloadTaskStatus.complete:
              statusString = 'completed';
              break;
            case DownloadTaskStatus.failed:
              statusString = 'failed';
              break;
            case DownloadTaskStatus.canceled:
              statusString = 'canceled';
              break;
            case DownloadTaskStatus.paused:
              statusString =
                  'paused'; // <--- Fixed string literal and added semicolon
              break;
            default:
              statusString = 'unknown';
          }
          currentProgress = task.progress;
        }

        // Emit an event to the web view to inform about the resumption with actual status and progress
        eventEmitter('download.progress', {
          'id': newTaskId,
          'status': 'downloading', // Explicitly set to downloading
          'progress': currentProgress,
        });
        return BridgeResponse.success({'id': newTaskId});
      } else {
        return BridgeResponse.error(-1, '未找到暂停下载的任务');
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _cancelDownload(Map<String, dynamic> params) async {
    debugPrint('[_cancelDownload] Received params: $params');
    try {
      final id = params['id'] as String?;
      if (id == null) {
        debugPrint('[_cancelDownload] Error: Download ID is required');
        return BridgeResponse.error(-1, 'Download ID is required');
      }
      debugPrint('[_cancelDownload] Attempting to cancel download with ID: $id');
      await FlutterDownloader.cancel(taskId: id);
      debugPrint('[_cancelDownload] FlutterDownloader.cancel completed for ID: $id');
      // Emit an event to the web view to inform about the cancellation
      eventEmitter('download_canceled', {'id': id});
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getDownloadStatus(Map<String, dynamic> params) async {
    try {
      final id = params['id'] as String?;
      if (id == null) {
        return BridgeResponse.error(-1, 'Download ID is required');
      }

      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
          query: 'SELECT * FROM task WHERE task_id="$id"');
      if (tasks != null && tasks.isNotEmpty) {
        final task = tasks.first;
        String statusString;
        switch (task.status) {
          case DownloadTaskStatus.enqueued:
            statusString = 'enqueued';
            break;
          case DownloadTaskStatus.running:
            statusString = 'downloading';
            break;
          case DownloadTaskStatus.complete:
            statusString = 'completed';
            break;
          case DownloadTaskStatus.failed:
            statusString = 'failed';
            break;
          case DownloadTaskStatus.canceled:
            statusString = 'canceled';
            break;
          case DownloadTaskStatus.paused:
            statusString = 'paused';
            break;
          default:
            statusString = 'unknown';
        }

        final result = {
          'id': task.taskId,
          'progress': task.progress,
          'status': statusString,
          'path': '${task.savedDir}/${task.filename}', // Construct full path
        };
        return BridgeResponse.success(result);
      } else {
        return BridgeResponse.error(-1, 'Download task not found for ID: $id');
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getDownloadList() async {
    try {
      final tasks = await FlutterDownloader.loadTasks();
      final List<Map<String, dynamic>> taskList = [];
      if (tasks != null) {
        for (var task in tasks) {
          String statusString;
          switch (task.status) {
            case DownloadTaskStatus.enqueued:
              statusString = 'enqueued';
              break;
            case DownloadTaskStatus.running:
              statusString = 'downloading';
              break;
            case DownloadTaskStatus.complete:
              statusString = 'completed';
              break;
            case DownloadTaskStatus.failed:
              statusString = 'failed';
              break;
            case DownloadTaskStatus.canceled:
              statusString = 'canceled';
              break;
            case DownloadTaskStatus.paused:
              statusString = 'paused';
              break;
            default:
              statusString = 'unknown';
          }
          taskList.add({
            'id': task.taskId,
            'url': task.url,
            'status': statusString,
            'progress': task.progress,
            'fileName': task.filename,
            'savedDir': task.savedDir,
          });
        }
      }
      return BridgeResponse.success(taskList);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _downloadM3u8(Map<String, dynamic> params) async {
    debugPrint('[_downloadM3u8] Received params: $params');
    try {
      final m3u8Url = params['url'] as String?;
      final fileName = params['fileName'] as String? ??
          'm3u8_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final taskId = params['id'] as String? ??
          'm3u8_download_${DateTime.now().millisecondsSinceEpoch}'; // Unique ID for tracking

      if (m3u8Url == null || m3u8Url.isEmpty) {
        debugPrint('[_downloadM3u8] Error: M3U8 URL is required');
        return BridgeResponse.error(-1, 'M3U8 URL is required');
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final outputFilePath = '${appDocDir.path}/$fileName';

      // FFmpeg command to download M3U8 and save as MP4
      final ffmpegCommand =
          '-i "$m3u8Url" -c copy -bsf:a aac_adtstoasc -y "$outputFilePath"';

      debugPrint('[_downloadM3u8] Executing FFmpeg command: $ffmpegCommand');

      // Enable statistics callback for progress updates
      FFmpegKitConfigPackage.FFmpegKitConfig.enableStatisticsCallback((statistics) {
        debugPrint('[_downloadM3u8] FFmpeg statistics callback triggered: ${statistics.getTime()}ms, ${statistics.getSize()} bytes');
        // Emit raw statistics as percentage progress is not directly available without total duration
        eventEmitter('m3u8.download.progress', {
          'id': taskId,
          'url': m3u8Url,
          'time': statistics.getTime(),
          'size': statistics.getSize(),
          'speed': statistics.getSpeed(),
        });
      });

      // Execute FFmpeg command asynchronously
      await FFmpegKitPackage.FFmpegKit.executeAsync(ffmpegCommand, (session) async {
        final returnCode = await session.getReturnCode();
        if (FFmpegReturnCodePackage.ReturnCode.isSuccess(returnCode)) {
          debugPrint('[_downloadM3u8] M3U8 download and merge successful: $outputFilePath');
          eventEmitter('m3u8.download.completed', {
            'id': taskId,
            'url': m3u8Url,
            'path': outputFilePath,
            'fileName': fileName,
          });
        } else if (FFmpegReturnCodePackage.ReturnCode.isCancel(returnCode)) {
          debugPrint('[_downloadM3u8] M3U8 download cancelled.');
          eventEmitter('m3u8.download.canceled', {
            'id': taskId,
            'url': m3u8Url,
            'fileName': fileName,
          });
        } else {
          final failStackTrace = await session.getFailStackTrace();
          debugPrint('[_downloadM3u8] M3U8 download failed. Return code: $returnCode, Stack trace: $failStackTrace');
          eventEmitter('m3u8.download.failed', {
            'id': taskId,
            'url': m3u8Url,
            'fileName': fileName,
            'error': failStackTrace ?? 'Unknown error',
          });
        }
        // Disable statistics callback after completion
        FFmpegKitConfigPackage.FFmpegKitConfig.enableStatisticsCallback(null);
      });

      return BridgeResponse.success({'id': taskId, 'path': outputFilePath});
    } catch (e) {
      debugPrint('[_downloadM3u8] Exception during M3U8 download: $e');
      // Disable statistics callback on error
      FFmpegKitConfigPackage.FFmpegKitConfig.enableStatisticsCallback(null);
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getDefaultDir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultDownloadDirPath =
          prefs.getString(_defaultDownloadDirPathKey);
      if (defaultDownloadDirPath != null && defaultDownloadDirPath.isNotEmpty) {
        return BridgeResponse.success(defaultDownloadDirPath);
      } else {
        final downloadDir = await getApplicationDocumentsDirectory();
        return BridgeResponse.success(downloadDir.path);
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _setDefaultDir(Map<String, dynamic> params) async {
    debugPrint("_setDefaultDir----params=$params");
    try {
      final path = params['path'] as String?;
      if (path == null) {
        return BridgeResponse.error(-1, 'Path is required');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultDownloadDirPathKey, path);
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getFilePath(Map<String, dynamic> params) async {
    try {
      final id = params['id'] as String?;
      if (id == null) {
        return BridgeResponse.error(-1, 'Download ID is required');
      }

      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
          query: 'SELECT * FROM task WHERE task_id="$id"');
      if (tasks != null && tasks.isNotEmpty) {
        final task = tasks.first;
        final filePath = '${task.savedDir}/${task.filename}';
        return BridgeResponse.success(filePath);
      } else {
        return BridgeResponse.error(-1, 'Download task not found for ID: $id');
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _downloadApk(Map<String, dynamic> params) async {
    debugPrint("_downloadApk()---params==$params");
    try {
      final url = params['url'] as String?;
      final id = params['id'] as String? ??
          'apk_${DateTime.now().millisecondsSinceEpoch}';
      final fileName = params['fileName'] as String? ?? '$id.apk';

      if (url == null) {
        return BridgeResponse.error(-1, 'URL is required');
      }

      final prefs = await SharedPreferences.getInstance();
      final defaultDownloadDirPath =
          prefs.getString(_defaultDownloadDirPathKey);

      String savedDir;
      if (defaultDownloadDirPath != null && defaultDownloadDirPath.isNotEmpty) {
        savedDir = defaultDownloadDirPath;
      } else {
        final downloadDir =
            await getTemporaryDirectory(); // Use temporary directory
        savedDir = downloadDir.path;
      }

      final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: savedDir,
          fileName: fileName,
          showNotification: false,
          openFileFromNotification: false);

      if (taskId != null) {
        return BridgeResponse.success({
          'id': taskId,
          'path': '$savedDir/$fileName',
        });
      } else {
        return BridgeResponse.error(-1, 'Failed to enqueue APK download');
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _installApk(Map<String, dynamic> params) async {
    if (!Platform.isAndroid) {
      return BridgeResponse.error(-1, '仅支持安卓平台');
    }
    try {
      final path = params['path'] as String?;
      if (path == null) {
        return BridgeResponse.error(-1, 'Path is required');
      }
      final result =
          await _methodChannel.invokeMethod('installApk', {'path': path});
      return BridgeResponse.success(result);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _openApk(Map<String, dynamic> params) async {
    debugPrint("_openApk-----$params");
    try {
      final packageName = params['packageName'] as String?;
      if (packageName == null) {
        return BridgeResponse.error(-1, 'Package name is required');
      }
      final result = await _methodChannel
          .invokeMethod('openApp', {'packageName': packageName});
      return BridgeResponse.success(result);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _isApkInstalled(Map<String, dynamic> params) async {
    debugPrint("_isApkInstalled-----$params");
    try {
      final packageName = params['packageName'] as String?;
      if (packageName == null) {
        return BridgeResponse.error(-1, 'Package name is required');
      }
      final result = await _methodChannel
          .invokeMethod('isAppInstalled', {'packageName': packageName});
      return BridgeResponse.success(result);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getCacheSize() async {
    try {
      final tasks = await FlutterDownloader.loadTasks();
      int totalSize = 0;

      if (tasks != null) {
        for (var task in tasks) {
          if (task.status == DownloadTaskStatus.complete) {
            final filePath = '${task.savedDir}/${task.filename}';
            final file = File(filePath);
            if (await file.exists()) {
              totalSize += await file.length();
            }
          }
        }
      }

      return BridgeResponse.success({
        'size': totalSize,
        'unit': 'bytes',
      });
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _clearCache(Map<String, dynamic> params) async {
    try {
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks != null) {
        for (var task in tasks) {
          // For simplicity, let's clear all completed tasks for now.
          // A more robust implementation might consider the 'type' parameter.
          if (task.status == DownloadTaskStatus.complete) {
            await FlutterDownloader.remove(
                taskId: task.taskId, shouldDeleteContent: true);
          }
        }
      }
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _getThumbnailForM3u8(Map<String, dynamic> params) async {
    try {
      final m3u8Url = params['url'] as String?;
      final outputPath = params['outputPath'] as String?;
      final width = params['width'] as int? ?? 320;
      final height = params['height'] as int? ?? 180;
      final time = params['time'] as int? ?? 1000; // time in milliseconds

      if (m3u8Url == null || m3u8Url.isEmpty || outputPath == null || outputPath.isEmpty) {
        return BridgeResponse.error(-1, 'M3U8 URL and output path are required');
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final outputFilePath = '${appDocDir.path}/$outputPath';

      // FFmpeg command to extract a single frame from the M3U8 at a specific time
      final ffmpegCommand = '-i "$m3u8Url" -ss ${time / 1000} -y -vframes 1 -vf "scale=${width}:${height}" "$outputFilePath"';

      debugPrint('[_getThumbnailForM3u8] Executing FFmpeg command: $ffmpegCommand');

      await FFmpegKitPackage.FFmpegKit.executeAsync(ffmpegCommand, (session) async {
        final returnCode = await session.getReturnCode();
        if (FFmpegReturnCodePackage.ReturnCode.isSuccess(returnCode)) {
          debugPrint('[_getThumbnailForM3u8] Thumbnail generated successfully: $outputFilePath');
          eventEmitter('m3u8.thumbnail.completed', {
            'url': m3u8Url,
            'path': outputFilePath,
          });
        } else {
          final failStackTrace = await session.getFailStackTrace();
          debugPrint('[_getThumbnailForM3u8] Thumbnail generation failed. Return code: $returnCode, Stack trace: $failStackTrace');
          eventEmitter('m3u8.thumbnail.failed', {
            'url': m3u8Url,
            'error': failStackTrace ?? 'Unknown error',
          });
        }
      });

      return BridgeResponse.success({'path': outputFilePath});
    } catch (e) {
      debugPrint('[_getThumbnailForM3u8] Exception during thumbnail generation: $e');
      return BridgeResponse.error(-1, e.toString());
    }
  }

  @override
  List<String> getCapabilities() {
    return [
      'download.start',
      'download.pause',
      'download.resume',
      'download.cancel',
      'download.status',
      'download.list',
      'download.m3u8',
      'download.getDefaultDir',
      'download.setDefaultDir',
      'download.getFilePath',
      'apk.download',
      'apk.install',
      'apk.open',
      'apk.isInstalled',
      'cache.getSize',
      'cache.clear',
    ];
  }
}
