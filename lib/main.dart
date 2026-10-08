import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:filetrack/screens/login_screen.dart';
import 'package:filetrack/services/language_service.dart';
import 'package:filetrack/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.instance.initLanguage();
  SyncService.instance.startAutoSyncTimer();
  runApp(const FileTrackApp());
}

class FileTrackApp extends StatelessWidget {
  const FileTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.instance.currentLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'FileTrack',
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
            Locale('en', ''),
          ],
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
      },
    );
  }
}
