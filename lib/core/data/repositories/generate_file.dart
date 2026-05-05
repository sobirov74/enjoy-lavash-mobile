import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:share_plus/share_plus.dart';

class ReportsService {
  final ApiClient apiClient;
  ReportsService(this.apiClient);
  Future<File> downloadExcelReport({required String id}) async {
    final res = await apiClient.dio.post(
      '${ApiEndpoints.orders}generate-files',
      data: {"file_type": 'excel', "order_id": id},
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = Uint8List.fromList(res.data ?? const <int>[]);

    final fileName =
        fileNameFromHeaders(res.headers) ??
        'report-${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final dir = await getTemporaryDirectory(); // best for sharing
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  String? fileNameFromHeaders(Headers headers) {
    final cd = headers.value('content-disposition');
    if (cd == null) return null;

    // attachment; filename="report.xlsx"
    // attachment; filename*=UTF-8''report%20name.xlsx
    final regExp = RegExp(
      "filename\\*=UTF-8''([^;\\n]+)|filename=\"?([^\";\\n]+)\"?",
      caseSensitive: false,
    );

    final match = regExp.firstMatch(cd);
    final name = match?.group(1) ?? match?.group(2);
    if (name == null) return null;

    return Uri.decodeFull(name.trim());
  }

  /// Share using SharePlus
  Future<void> shareExcelFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        title: "Report",
        files: [XFile(file.path, mimeType: _xlsxMime)],
        subject: 'Excel report',
      ),
    );
  }

  static const _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
}
