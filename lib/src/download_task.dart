import 'dart:async';
import 'dart:io';

import 'exceptions/accept_range_exception.dart';
import 'exceptions/already_running_exception.dart';
import 'exceptions/invalid_file_exception.dart';
import 'task_update.dart';

/// Contains a [DownloadTask] object
class DownloadTask {
  /// The corresponding id for the task
  final int id;

  /// The path to the file
  final String filePath;

  /// The url of the file
  final String url;

  /// The headers used for the server
  final Map<String, String> headers;
  final DownloadTaskUpdate _update;
  int _totalBytes = 1;
  int _bytesDone = 0;
  StreamSubscription<List<int>> _downloadStream;
  IOSink _sink;
  bool _acceptsRange;
  bool _isRunning = false;
  bool _isCanceled = false;
  dynamic _error;

  ///
  DownloadTask(this.id,
      this.filePath,
      this.url,
      this._update, {
        this.headers = const {},
      });

  /// Whether this task is currently downloading
  bool get isRunning => _isRunning;

  /// Whether this task is canceled or not
  bool get isCanceled => _isCanceled;

  IOSink get _fileSink => _file.openWrite();

  File get _file => File(filePath);

  /// Get the current data as a [TaskUpdate]
  TaskUpdate get current =>
      TaskUpdate(
        id,
        _totalBytes,
        _bytesDone,
        _error,
        _acceptsRange,
      );

  /// Start the download
  Future<void> start() async {
    _isRunning = true;
    HttpClientResponse response;
    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
      response = await request.close();
    } on Exception catch (e) {
      _error = e;
      _isRunning = false;
      _isCanceled = true;
      _update(current);
      return;
    }
    final acceptRanges = response.headers.value(HttpHeaders.acceptRangesHeader);
    _acceptsRange = acceptRanges != null && acceptRanges != 'none';
    _totalBytes = response.contentLength;
    _update(current);
    _sink = _fileSink;
    _downloadStream = response.listen(
          (event) {
        _bytesDone += event.length;
        _update(current);
        _sink?.add(event);
      },
      onDone: () async {
        await _sink?.flush();
        await _sink?.close();
        _isRunning = false;
        _update(current);
      },
      onError: (err) async {
        _error = err;
        await _sink?.flush();
        await _sink?.close();
        _isRunning = false;
        _isCanceled = true;
        _update(current);
      },
      cancelOnError: true,
    );
  }

  /// Resume a canceled download
  ///
  /// This throws a [ResumeException] if the file has changed after [cancel] or
  /// the server does not support "Range" request ([_acceptsRange])
  Future<void> resume() async {
    if (_isRunning) {
      throw AlreadyRunningException();
    }
    if (!_acceptsRange) {
      throw AcceptRangeException();
    }
    final fileLength = await _file.length();
    if (fileLength != _bytesDone) {
      throw InvalidFileException(filePath, _bytesDone, fileLength);
    }
    _isRunning = true;
    _isCanceled = false;
    final request = await HttpClient().getUrl(Uri.parse(url));
    headers.forEach((key, value) {
      request.headers.add(key, value);
    });
    request.headers
        .add(HttpHeaders.rangeHeader, 'bytes=$_bytesDone-$_totalBytes');
    final response = await request.close();
    _sink = _fileSink;
    _downloadStream = response.listen((event) {
      _bytesDone += event.length;
      _update(current);
      _sink?.add(event);
    }, onDone: () async {
      await _sink?.flush();
      await _sink?.close();
      _isRunning = false;
      _update(current);
    });
  }

  /// Cancel the download
  Future<void> cancel() async {
    _isRunning = false;
    _isCanceled = true;
    await _downloadStream?.cancel();
    await _sink?.flush();
    await _sink?.close();
    _update(current);
  }
}
