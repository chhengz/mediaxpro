import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'backend_config.dart';

class ApiService {
  final Dio _dio = Dio();
  final MediaStore _mediaStore = MediaStore();

  Future<String> _getBaseUrl() async => await BackendConfig.getUrl();

  /// Fetches video metadata
  Future<Map<String, dynamic>> analyze(String url) async {
    final baseUrl = await _getBaseUrl();
    final response = await _dio.post(
      "$baseUrl/analyze",
      data: {"url": url},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data;
  }

  /// Downloads and saves to Public Gallery
  Future<void> downloadVideo({
    required String url,
    required String formatId,
    required String filename,
    required Function(double) onProgress,
  }) async {
    // 1. Request Permissions
    if (Platform.isAndroid) {
      await [Permission.storage, Permission.videos].request();
    }

    final baseUrl = await _getBaseUrl();

    // 2. Open Stream from Backend
    final response = await _dio.post(
      "$baseUrl/stream",
      data: {"url": url, "format_id": formatId},
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 15), // Large videos take time
      ),
    );

    // 3. Save to Temporary File first
    final tempDir = await getTemporaryDirectory();
    final tempFile = File("${tempDir.path}/$filename");
    final sink = tempFile.openWrite();

    final total = int.tryParse(response.headers.value('content-length') ?? "-1") ?? -1;
    int received = 0;

    await for (final List<int> chunk in response.data.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(total > 0 ? (received / total) : -1.0);
    }
    await sink.close();

    // 4. Move to MediaStore (Gallery)
    await _mediaStore.saveFile(
      tempFilePath: tempFile.path,
      dirType: DirType.video,
      dirName: DirName.movies,
      relativePath: "mediaxpro",
    );

    // 5. Cleanup
    if (await tempFile.exists()) await tempFile.delete();
  }
}