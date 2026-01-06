import 'package:shared_preferences/shared_preferences.dart';

class BackendConfig {
  static const _key = 'backend_url';
  // Default to your current local IP
  static const defaultUrl = 'http://10.1.35.38:8000';

  static Future<String> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? defaultUrl;
  }

  static Future<void> setUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String cleanUrl = url.trim();
    // Ensure URL has protocol
    if (!cleanUrl.startsWith('http')) {
      cleanUrl = 'http://$cleanUrl';
    }
    // Remove trailing slash
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    await prefs.setString(_key, cleanUrl);
  }
}