import 'download_manager_exception.dart';

/// Thrown if trying to resume an already running download
class AlreadyRunningException extends DownloadManagerException {
  @override
  String toString() {
    return 'AlreadyRunningException:'
        ' Tried to resume a download that is already running';
  }
}
