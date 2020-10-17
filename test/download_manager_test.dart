import 'dart:io';

import 'package:download_manager/download_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() async {
  group('Range tests', () {
    test('Range available test', () async {
      final id = await DownloadManager.instance
          .addTask('http://ipv4.download.thinkbroadband.com/100MB.zip', 'data.bin');
      final info = DownloadManager.instance.getTask(id);
      expect(info.isResumeAble, true);
      expect(info.id, id);
      expect(info.progress, info.bytesDone / info.totalBytes);
      // 104857600 Bytes == 100 Megabytes
      expect(info.totalBytes, 104857600);
      expect(info.hasError, false);
      DownloadManager.instance.removeTask(id);
    });

    test('Error test', () async {
      final id = await DownloadManager.instance
          .addTask('https://unavailable.unavailable/', 'data.bin');
      final info = DownloadManager.instance.getTask(id);
      expect(info.hasError, true);
      DownloadManager.instance.removeTask(id);
    });
  });
}
