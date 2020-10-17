import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'download_task.dart';
import 'task_update.dart';

/// The top level class for adding new [DownloadTask]s
///
/// It can be accessed through the singleton [instance]
class DownloadManager {
  final Map<int, DownloadTask> _tasks = {};
  final List<DownloadTaskUpdate> _listeners = [];

  /// The maximum number of concurrent downloads
  int maxConcurrent = Platform.numberOfProcessors ~/ 2;

  int get _running => _tasks.values.where((e) => e.isRunning).length;

  bool get _canStartTask => maxConcurrent > _running;

  int get _unfinishedTaskId {
    for (final task in _tasks.values) {
      if (!task.isRunning && !task.isCanceled) {
        return task.id;
      }
    }
    // ignore: avoid_returning_null
    return null;
  }

  int _getId() => Random().nextInt(9999);

  static DownloadManager _instance;

  /// Get a new instance
  static DownloadManager get instance {
    _instance ??= DownloadManager();
    return _instance;
  }

  /// Get notified when a [DownloadTask] changes state
  void addListener(DownloadTaskUpdate taskUpdate) => _listeners.add(taskUpdate);

  /// Remove the specified notifier
  void removeListener(DownloadTaskUpdate taskUpdate) =>
      _listeners.remove(taskUpdate);

  Future<void> _startNextTask() async {
    final nextTask = _unfinishedTaskId;
    if (nextTask != null && _canStartTask) {
      await _tasks[nextTask]?.start();
    }
  }

  void _notifyListeners(TaskUpdate task) {
    if (task.isDone) {
      _tasks.remove(task.id);
      _startNextTask();
    }
    for (final listener in _listeners) {
      listener(task);
    }
  }

  /// Removes a task from the list
  ///
  /// If the task is running, it will be canceled
  Future<void> removeTask(int taskId) async {
    await cancelTask(taskId);
    _tasks.remove(taskId);
  }

  /// Get the last taskUpdate for the specified id
  TaskUpdate getTask(int taskId) => _tasks[taskId]?.current;

  /// Resume the task with the specified [taskId]
  ///
  /// This will ignore the [maxConcurrent] limit
  Future<void> resumeTask(int taskId) async {
    final task = _tasks[taskId];
    if ((task?.isCanceled ?? false)) {
      await _tasks[taskId]?.resume();
    }
  }

  /// Cancel the task with the specified [taskId]
  Future<void> cancelTask(int taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      await task.cancel();
    }
  }

  /// Create a new [DownloadTask] the id of the task will be returned.
  Future<int> addTask(
    String url,
    String filePath, {
    Map<String, String> headers = const {},
  }) async {
    final taskId = _getId();
    final task =
        DownloadTask(taskId, filePath, url, _notifyListeners, headers: headers);
    if (_canStartTask) {
      await task.start();
    }
    _tasks.putIfAbsent(taskId, () => task);
    return taskId;
  }
}
