import 'package:flutter/material.dart';
import 'package:filetrack/screens/login_screen.dart';
import 'package:filetrack/services/sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SyncService.instance.startAutoSyncTimer();
  runApp(const FileTrackApp());
}

class FileTrackApp extends StatelessWidget {
  const FileTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FileTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005691),
          primary: const Color(0xFF005691),
          secondary: const Color(0xFF0088CC),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
