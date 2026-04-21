import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalization {
  final Locale locale;

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  Map<String, String> _localizedStrings = {};

  /// Load file JSON
  Future<void> load() async {
    try {
      String jsonStringValues = await rootBundle
          .loadString('lib/lang/${locale.languageCode}.json');

      Map<String, dynamic> mappedJson = json.decode(jsonStringValues);

      _localizedStrings = mappedJson.map(
            (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      // nếu lỗi load file
      print("❌ Load language error: $e");
      _localizedStrings = {};
    }
  }

  /// Translate function (ANTI-CRASH)
  String translate(String key) {
    if (_localizedStrings == null) return key;

    return _localizedStrings[key] ?? key;
  }

  /// Delegate
  static const LocalizationsDelegate<AppLocalization> delegate =
  _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'vi', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    AppLocalization localization = AppLocalization(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalization> old) => false;
}