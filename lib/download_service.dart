import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';

class DownloadService {
  final Dio _dio = Dio();

  // Update this to your server's current local IP
  final String _baseUrl = "http://192.168.100.25:8000";

  /// Fetches video metadata (title and available formats)
  Future<Map<String, dynamic>> analyze(String url) async {
    try {
      final response = await _dio.post(
        "$_baseUrl/analyze",
        data: {"url": url},
      );
      return response.data;
    } catch (e) {
      // print("Analyze Error: $e");
      rethrow;
    }
  }

  /// Downloads the stream from the backend and saves to Android MediaStore
  Future<void> download({
    required String url,
    required String formatId,
    required String filename,
    required Function(double) onProgress,
  }) async {
    try {
      // 1. Request the stream from the backend
      final response = await _dio.post(
        "$_baseUrl/stream",
        data: {
          "url": url,
          "format_id": formatId,
        },
        options: Options(
          responseType: ResponseType.stream,
          // Merge operations take time; give the server up to 10 mins to process
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // 2. Prepare temporary storage
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/$filename");

      // Use IOSink for better memory management while streaming large files
      final sink = tempFile.openWrite();

      // 3. Track progress
      final contentLength = response.headers.value('content-length');
      int total = int.tryParse(contentLength ?? "-1") ?? -1;
      int received = 0;

      // 4. Stream data chunks from backend to local file
      await for (final List<int> chunk in response.data.stream) {
        sink.add(chunk);
        received += chunk.length;

        if (total > 0) {
          // Standard progress (0.0 to 1.0)
          onProgress(received / total);
        } else {
          // Indeterminate progress (backend is likely merging A/V on the fly)
          onProgress(-1.0);
        }
      }

      // Close the file handle after download completes
      await sink.close();

      // 5. Save the file to the Public Gallery (Movies/mediaxpro)
      final mediaStore = MediaStore();

      final saveInfo = await mediaStore.saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.video,
        dirName: DirName.movies,
        relativePath: "mediaxpro",
      );

      // 6. Clean up: Delete the temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Final check on save status
      // if (saveInfo == null || saveInfo.status == SaveStatus.failed) {
      //   throw Exception("Failed to save file to MediaStore");
      // }

      if (saveInfo == null) {
        throw Exception("Failed to save file to MediaStore: Response was null");
      }

    } catch (e) {
      // print("Download Service Error: $e");
      rethrow;
    }
  }
}