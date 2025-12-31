import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'download_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = "mediaxpro";
  }
  runApp(const MediaXProApp());
}

class MediaXProApp extends StatefulWidget {
  const MediaXProApp({super.key});
  @override
  State<MediaXProApp> createState() => _MediaXProAppState();
}

class _MediaXProAppState extends State<MediaXProApp> {
  ThemeMode themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: DownloadPage(
        onThemeToggle: () => setState(() => themeMode =
        themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light),
      ),
    );
  }
}

class DownloadPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const DownloadPage({super.key, required this.onThemeToggle});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  final DownloadService _service = DownloadService();

  // add more link
  void _addNewInput() => setState(() => _controllers.add(TextEditingController()));



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MediaXPro"),
        actions: [
          IconButton(icon: const Icon(Icons.brightness_6), onPressed: widget.onThemeToggle),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _controllers.length,
              itemBuilder: (context, index) => VideoDownloadCard(
                controller: _controllers[index],
                service: _service,
                onRemove: () {
                  setState(() {
                    _controllers[index].dispose();
                    _controllers.removeAt(index);
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addNewInput,
              icon: const Icon(Icons.add),
              label: const Text("Add Another Link"),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoDownloadCard extends StatefulWidget {
  final TextEditingController controller;
  final DownloadService service;
  final VoidCallback onRemove;
  // const VideoDownloadCard({super.key, required this.controller, required this.service});

  const VideoDownloadCard({
    super.key,
    required this.controller,
    required this.service,
    required this.onRemove,
  });

  @override
  State<VideoDownloadCard> createState() => _VideoDownloadCardState();
}

class _VideoDownloadCardState extends State<VideoDownloadCard> {
  bool isAnalyzing = false;
  bool isDownloading = false;
  double progress = 0.0;
  Map<String, dynamic>? videoData;
  String? selectedFormat;

  // 1. Analyze the URL to get Title and Formats
  Future<void> _analyzeUrl() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty) return;

    setState(() => isAnalyzing = true);
    try {
      // You need to add this 'analyze' method to your DownloadService!
      final data = await widget.service.analyze(url);
      setState(() {
        videoData = data;
        selectedFormat = data['formats'].isNotEmpty ? data['formats'][0]['format_id'] : null;
      });
    } catch (e) {
      // Check again before showing the SnackBar
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid URL or Server Down")));
    } finally {
      setState(() => isAnalyzing = false);
    }
  }

  // 2. Start the download with the selected Format ID
  Future<void> _startDownload() async {
    if (videoData == null || selectedFormat == null) return;

    setState(() {
      isDownloading = true;
      progress = 0.0;
    });

    try {
      final cleanTitle = videoData!['title'].toString().replaceAll(RegExp(r'[^\w\s]+'), '');
      await widget.service.download(
        url: widget.controller.text.trim(),
        formatId: selectedFormat!,
        filename: "$cleanTitle.mp4",
        onProgress: (p) => setState(() => progress = p),
      );

      // Check again before showing the SnackBar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to Gallery!")));
    } catch (e) {
      // Check again before showing the SnackBar
      // if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: "Paste Video URL here",
                      suffixIcon: IconButton(
                        icon: isAnalyzing
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.search),
                        onPressed: isAnalyzing ? null : _analyzeUrl,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onRemove,
                  tooltip: "Remove",
                ),
              ],
            ),
            // TextField(
            //   controller: widget.controller,
            //   decoration: InputDecoration(
            //     hintText: "Paste Video URL here",
            //     suffixIcon: IconButton(
            //       icon: isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
            //       onPressed: isAnalyzing ? null : _analyzeUrl,
            //     ),
            //   ),
            // ),
            if (videoData != null) ...[
              const SizedBox(height: 12),
              Text(videoData!['title'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedFormat,
                isExpanded: true,
                items: (videoData!['formats'] as List).map((f) {
                  return DropdownMenuItem<String>(
                    value: f['format_id'].toString(),
                    child: Text("${f['resolution']} (${f['ext']}) - ${f['note']} - ${f['filesize']}"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedFormat = val),
              ),
              const SizedBox(height: 12),
              if (isDownloading) ...[
                LinearProgressIndicator(value: progress > 0 ? progress : null),
                const SizedBox(height: 4),
                Text(progress > 0 ? "${(progress * 100).toInt()}%" : "Processing on server..."),
              ] else
                ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
                ),
            ]
          ],
        ),
      ),
    );
  }
}