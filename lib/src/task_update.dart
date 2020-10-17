import 'download_task.dart';

typedef DownloadTaskUpdate = void Function(TaskUpdate);

/// Update progress for an [DownloadTask]
class TaskUpdate {
  /// The [id] of the [DownloadTask]
  final int id;

  /// The amount of total downloaded bytes
  final int totalBytes;

  /// The content length of the response
  final int bytesDone;

  /// The error object, if the download failed
  final dynamic error;

  ///
  final bool isResumeAble;

  ///
  TaskUpdate(
    this.id,
    this.totalBytes,
    this.bytesDone,
    this.error,
    // ignore: avoid_positional_boolean_parameters
    this.isResumeAble,
  );

  /// Returns true if the file download succeeded
  bool get isDone => totalBytes == bytesDone;

  /// The download progress in decimal e.g. (0.75232)
  double get progress => bytesDone / totalBytes;

  /// Checks if the download failed with an error
  bool get hasError => error != null;
}
