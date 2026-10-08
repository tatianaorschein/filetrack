import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static final LanguageService instance = LanguageService._init();

  LanguageService._init();

  final ValueNotifier<Locale> currentLocale = ValueNotifier<Locale>(const Locale('fr'));

  Future<void> initLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language') ?? 'fr';
    currentLocale.value = Locale(langCode);
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode != 'fr' && langCode != 'en') return;

    currentLocale.value = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
  }

  bool get isFrench => currentLocale.value.languageCode == 'fr';
}
