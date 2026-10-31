import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  /// Loads persisted language from SharedPreferences ('fr' or 'ar')
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final code = p.getString('lang') ?? 'fr';
      _locale = code == 'ar' ? const Locale('ar', 'MA') : const Locale('fr');
    } catch (_) {
      _locale = const Locale('fr');
    }
    notifyListeners();
  }

  /// Sets language code ('fr' or 'ar') and persists to SharedPreferences
  Future<void> setLocale(String code) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('lang', code);
    } catch (_) {}
    _locale = code == 'ar' ? const Locale('ar', 'MA') : const Locale('fr');
    notifyListeners();
  }
}
