import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

ValueNotifier<bool> isDarkModeGlobal = ValueNotifier(false);

bool get isDarkMode => isDarkModeGlobal.value;

final backGroundColor = CupertinoDynamicColor.withBrightness(
  color: Colors.white,
  darkColor: Color(0xFF1C1C1E),
);

class AppTheme {
  static Color background() => isDarkMode ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
  static Color surface() => isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
  static Color card() => isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
  static Color textPrimary() => isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
  static Color textSecondary() => isDarkMode ? Colors.grey : const Color(0xFF8E8E93);
  static Color divider() => isDarkMode ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
  static Color tabActive() => isDarkMode ? const Color(0xFF64D2FF) : const Color(0xFF00BFA5);
  static Color icon() => isDarkMode ? Colors.white : const Color(0xFF8E8E93);
}