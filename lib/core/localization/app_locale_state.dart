import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLanguageCodeKey = 'vegora_app_language_code';

/// Riverpod provider managing the active application locale (English or Tamil).
final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(() {
  return AppLocaleNotifier();
});

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSavedLocale();
    return const Locale('en');
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLanguageCodeKey);
      if (code != null && (code == 'en' || code == 'ta')) {
        state = Locale(code);
      }
    } catch (_) {
      // Fallback to default
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state.languageCode == newLocale.languageCode) return;
    state = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguageCodeKey, newLocale.languageCode);
    } catch (_) {}
  }

  Future<void> setLanguage(String languageCode) async {
    await setLocale(Locale(languageCode));
  }

  Future<void> toggleLanguage() async {
    final nextCode = state.languageCode == 'en' ? 'ta' : 'en';
    await setLocale(Locale(nextCode));
  }
}
