import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const HomePage({super.key, required this.onThemeToggle});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MediaXPro"),
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackendSettingsPage())), icon: const Icon(Icons.settings)),
          IconButton(onPressed: widget.onThemeToggle, icon: const Icon(Icons.brightness_6)),
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
                service: _apiService,
                onRemove: () => setState(() => _controllers.removeAt(index)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(onPressed: () => setState(() => _controllers.add(TextEditingController())), icon: const Icon(Icons.add), label: const Text("Add Link")),
          ),
        ],
      ),
    );
  }
}

class VideoDownloadCard extends StatefulWidget {
  final TextEditingController controller;
  final ApiService service;
  final VoidCallback onRemove;
  const VideoDownloadCard({super.key, required this.controller, required this.service, required this.onRemove});

  @override
  State<VideoDownloadCard> createState() => _VideoDownloadCardState();
}

class _VideoDownloadCardState extends State<VideoDownloadCard> {
  bool isAnalyzing = false;
  bool isDownloading = false;
  double progress = 0.0;
  Map<String, dynamic>? videoData;
  String? selectedFormat;

  Future<void> _analyze() async {
    setState(() => isAnalyzing = true);
    try {
      final data = await widget.service.analyze(widget.controller.text);
      setState(() {
        videoData = data;
        selectedFormat = (data['formats'] as List).first['format_id'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error analyzing URL")));
    } finally {
      setState(() => isAnalyzing = false);
    }
  }

  Future<void> _download() async {
    setState(() => isDownloading = true);
    try {
      final title = videoData!['title'].toString().replaceAll(RegExp(r'[^\w\s]+'), '');
      await widget.service.downloadVideo(
        url: widget.controller.text,
        formatId: selectedFormat!,
        filename: "$title.mp4",
        onProgress: (p) => setState(() => progress = p),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Download Complete!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Download Failed: $e")));
    } finally {
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: "Video URL",
                suffixIcon: IconButton(onPressed: isAnalyzing ? null : _analyze, icon: isAnalyzing ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.search)),
              ),
            ),
            if (videoData != null) ...[
              const SizedBox(height: 10),
              Text(videoData!['title'], maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedFormat,
                isExpanded: true,
                onChanged: (v) => setState(() => selectedFormat = v),
                items: (videoData!['formats'] as List).map((f) => DropdownMenuItem(value: f['format_id'].toString(), child: Text("${f['resolution']} - ${f['note']}"))).toList(),
              ),
              if (isDownloading) LinearProgressIndicator(value: progress > 0 ? progress : null)
              else ElevatedButton(onPressed: _download, child: const Text("Download")),
            ],
            TextButton(onPressed: widget.onRemove, child: const Text("Remove", style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}