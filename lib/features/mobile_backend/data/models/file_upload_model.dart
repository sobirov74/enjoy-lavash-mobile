import 'json_helpers.dart';

class FileUploadRequest {
  const FileUploadRequest({
    required this.bytes,
    required this.filename,
    this.fieldName = 'file',
  });

  final List<int> bytes;
  final String filename;
  final String fieldName;

  static const int maxSizeBytes = 10 * 1024 * 1024;

  bool get isTooLarge => bytes.length > maxSizeBytes;
}

class FileUploadResultModel {
  const FileUploadResultModel({required this.url});

  final String url;

  factory FileUploadResultModel.fromJson(Map<String, dynamic> json) {
    return FileUploadResultModel(url: readString(json, const ['url']));
  }
}
