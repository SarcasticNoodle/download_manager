import 'package:download_manager/download_manager.dart';

void main() async {
  final taskId = await DownloadManager.instance
      .addTask('http://ipv4.download.thinkbroadband.com/100MB.zip', '100mb.bin');
  var canceled = false;
  DownloadManager.instance.addListener((task) async {
    // print the status eg: 3552: 12.32%
    print('${task.id}: ${(task.progress * 100).toStringAsFixed(2)}%');
    if (task.progress > 0.5 && !canceled) {
      // Cancel a task
      DownloadManager.instance.cancelTask(taskId);
      canceled = true;
      await Future.delayed(Duration(seconds: 10));
      // Resume a task
      DownloadManager.instance.resumeTask(taskId);
    }
  });
}
