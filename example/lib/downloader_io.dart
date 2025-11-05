import 'dart:ui';
import 'dart:isolate';

class DownloadTaskInfo {
  int lastProgress;
  DateTime lastUpdateTime;

  DownloadTaskInfo(this.lastProgress, this.lastUpdateTime);
}

final Map<String, DownloadTaskInfo> _downloadTasks = {};

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  if (send != null) {
    double speed = 0.0;
    if (status == 2) { // DownloadTaskStatus.running
      final now = DateTime.now();
      if (_downloadTasks.containsKey(id)) {
        final taskInfo = _downloadTasks[id]!;
        final timeDiff = now.difference(taskInfo.lastUpdateTime).inMilliseconds;
        if (timeDiff > 0) {
          final progressDiff = progress - taskInfo.lastProgress;
          speed = progressDiff / (timeDiff / 1000.0); // % per second
        }
        taskInfo.lastProgress = progress;
        taskInfo.lastUpdateTime = now;
      } else {
        _downloadTasks[id] = DownloadTaskInfo(progress, now);
      }
    } else {
      _downloadTasks.remove(id);
    }

    send.send({'id': id, 'status': status, 'progress': progress, 'speed': speed.toStringAsFixed(2) + 'kb/s'});
  }
}