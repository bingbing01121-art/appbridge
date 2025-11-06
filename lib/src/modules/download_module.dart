import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'dart:convert';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // Add dio
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart'; // Use ffmpeg_kit_flutter_new
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/foundation.dart';
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
    try {
      final id = params['id'] as String?;
      if (id == null) {
        return BridgeResponse.error(-1, 'Download ID is required');
      }
      await FlutterDownloader.pause(taskId: id);
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _resumeDownload(Map<String, dynamic> params) async {
    try {
      final id = params['id'] as String?;
      if (id == null) {
        return BridgeResponse.error(-1, 'Download ID is required');
      }
      final newTaskId = await FlutterDownloader.resume(taskId: id);
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
        eventEmitter('download_resumed', {
          'id': newTaskId,
          'status': statusString,
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
    try {
      final id = params['id'] as String?;
      if (id == null) {
        return BridgeResponse.error(-1, 'Download ID is required');
      }
      await FlutterDownloader.cancel(taskId: id);
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
    if (kIsWeb) {
      return BridgeResponse.error(
          -1, 'M3U8 downloads are not supported on the web platform.');
    }
    final m3u8Url = params['url'] as String?;
    final id = params['id'] as String?;

    if (m3u8Url == null || m3u8Url.isEmpty) {
      return BridgeResponse.error(-1, 'M3U8 URL is required');
    }
    if (id == null) {
      return BridgeResponse.error(-1, 'ID is required for m3u8 download');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${appDocDir.path}/m3u3_downloads');

    try {
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final outputFilePath =
          '${outputDir.path}/output_$id.mp4'; // Use provided ID for filename
      final arguments = ['-i', m3u8Url, '-c', 'copy', outputFilePath];

      FFmpegKit.executeAsync(arguments.join(' '), (session) async {
        final rc = await session.getReturnCode();
        if (ReturnCode.isSuccess(rc)) {
          final file = File(outputFilePath);
          if (await file.exists()) {
            final result = await ImageGallerySaver.saveFile(outputFilePath);
            final galleryPath = result['filePath'];
            if (galleryPath != null) {
              eventEmitter('m3u8_download_progress', {
                'id': id,
                'progress': 100,
                'status': 'completed',
                'path': galleryPath
              });
            } else {
              eventEmitter('m3u8_download_progress', {
                'id': id,
                'status': 'failed',
                'error': 'Failed to get gallery path.'
              });
            }
          } else {
            debugPrint('File does not exist at path: $outputFilePath');
            eventEmitter('m3u8_download_progress', {
              'id': id,
              'status': 'failed',
              'error': 'FFmpeg reported success, but output file not found.'
            });
          }
        } else {
          final output = await session.getOutput();
          debugPrint('FFmpeg command: ${arguments.join(' ')}');
          debugPrint('FFmpeg output: $output');
          eventEmitter('m3u8_download_progress', {
            'id': id,
            'status': 'failed',
            'error': 'FFmpeg failed with exit code $rc. Output: $output'
          });
        }
      }, (log) {
        // You can parse log messages here if needed
      }, (statistics) {
        final duration = params['duration'] as num?;
        if (duration != null && duration > 0) {
          // a rough progress calculation
          double progress = (statistics.getTime() / (duration * 1000));
          if (progress < 0) progress = 0;
          if (progress > 1) progress = 1;
          eventEmitter('m3u8_download_progress', {
            'id': id,
            'progress': (progress * 100).round(),
            'status': 'downloading'
          });
        } else {
          // If no duration, we can't calculate percentage, but we can still report activity.
          eventEmitter('m3u8_download_progress', {
            'id': id,
            'status': 'downloading',
            'processed_time': statistics.getTime()
          });
        }
      });

      return BridgeResponse.success({
        'id': id,
        'message': 'M3U8 download initiated.'
      }); // Return downloadId immediately
    } catch (e) {
      return BridgeResponse.error(
          -1, 'M3U8 download and combine failed: ${e.toString()}');
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

  Future<BridgeResponse> _getThumbnailForM3u8(
      Map<String, dynamic> params) async {
    if (kIsWeb) {
      return BridgeResponse.error(-1,
          'M3U8 thumbnail generation is not supported on the web platform.');
    }
    final m3u8Url = params['url'] as String?;
    if (m3u8Url == null || m3u8Url.isEmpty) {
      return BridgeResponse.error(-1, 'M3U8 URL is required');
    }

    try {
      final dio = Dio();
      final hlsPlaylist = await HlsPlaylistParser.create().parseString(
          Uri.parse(m3u8Url),
          await dio.get(m3u8Url).then((response) => response.data));

      HlsMediaPlaylist? mediaPlaylist;
      if (hlsPlaylist is HlsMasterPlaylist) {
        if (hlsPlaylist.variants.isNotEmpty) {
          final firstVariant = hlsPlaylist.variants.first;
          final firstMediaPlaylistUrl = firstVariant.url;
          mediaPlaylist = await HlsPlaylistParser.create().parseString(
              firstMediaPlaylistUrl,
              await dio
                  .get(firstMediaPlaylistUrl.toString())
                  .then((response) => response.data)) as HlsMediaPlaylist?;
        }
      } else if (hlsPlaylist is HlsMediaPlaylist) {
        mediaPlaylist = hlsPlaylist;
      }

      if (mediaPlaylist == null || mediaPlaylist.segments.isEmpty) {
        return BridgeResponse.error(
            -1, 'No segments found in the M3U8 playlist.');
      }

      final firstSegmentUrl = mediaPlaylist.segments.first.url;
      if (firstSegmentUrl == null) {
        return BridgeResponse.error(-1, 'First segment URL is null.');
      }

      final baseUrl = Uri.parse(m3u8Url).resolve('.');
      final absoluteSegmentUrl = baseUrl.resolve(firstSegmentUrl.toString());

      final appDocDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${appDocDir.path}/thumbnails');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      final outputImagePath =
          '${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final arguments = [
        '-i',
        absoluteSegmentUrl.toString(),
        '-vf',
        "select='eq(n,1)'",
        '-vframes',
        '1',
        outputImagePath
      ];

      final session = await FFmpegKit.execute(arguments.join(' '));
      final rc = await session.getReturnCode();

      if (ReturnCode.isSuccess(rc)) {
        final imageFile = File(outputImagePath);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          final base64Image = base64Encode(imageBytes);
          await imageFile.delete();
          return BridgeResponse.success(
              {'thumbnail': 'data:image/jpeg;base64,$base64Image'});
        } else {
          return BridgeResponse.error(-1, 'Thumbnail file was not created.');
        }
      } else {
        final output = await session.getOutput();
        return BridgeResponse.error(
            -1, 'FFmpeg failed to extract thumbnail. Output: $output');
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }
}
