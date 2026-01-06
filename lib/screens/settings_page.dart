import 'package:flutter/material.dart';
import '../services/backend_config.dart';

class BackendSettingsPage extends StatefulWidget {
  const BackendSettingsPage({super.key});

  @override
  State<BackendSettingsPage> createState() => _BackendSettingsPageState();
}

class _BackendSettingsPageState extends State<BackendSettingsPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    BackendConfig.getUrl().then((url) => _controller.text = url);
  }

  void _save() async {
    await BackendConfig.setUrl(_controller.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend URL updated!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://192.168.1.5:8000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text('Save')),
            )
          ],
        ),
      ),
    );
  }
}