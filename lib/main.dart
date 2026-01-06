import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';

// Import your other files
import 'screens/home_page.dart';

void main() async {
  // Required for plugin initializations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaStore for Android Gallery access
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    // Sets the sub-folder name inside the Movies directory
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
  // Default to Dark Mode
  ThemeMode _themeMode = ThemeMode.dark;

  /// Toggles between Light and Dark themes
  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaXPro',
      debugShowCheckedModeBanner: false,

      // Light Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blueAccent,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Dark Theme Configuration
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueAccent,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      themeMode: _themeMode,

      // Calling the HomePage and passing the toggle function
      home: HomePage(onThemeToggle: _toggleTheme),
    );
  }
}