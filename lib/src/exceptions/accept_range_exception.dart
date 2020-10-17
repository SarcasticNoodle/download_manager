import 'download_manager_exception.dart';

/// Thrown if the server does not support Ranges
class AcceptRangeException extends DownloadManagerException {
  @override
  String toString() {
    return 'The server responded with "Accept-Ranges: none" or didn\'t'
        'include the Accept-Ranges header. This blocks resumeable downloading';
  }
}
