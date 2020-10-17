import 'download_manager_exception.dart';

/// Thrown if the file got invalidated between cancel and resume
class InvalidFileException extends DownloadManagerException {
  /// The path to the invalid file
  final String filePath;

  /// The length of the file
  final int expectedFileLength;

  /// The bytes downloaded
  final int actualFileLength;

  ///
  InvalidFileException(
      this.filePath, this.expectedFileLength, this.actualFileLength);

  @override
  String toString() {
    return 'InvalidFileException: Expected File $filePath to be of length'
        ' $expectedFileLength but is $actualFileLength.';
  }
}
