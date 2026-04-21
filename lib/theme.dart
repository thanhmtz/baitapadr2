import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

ValueNotifier<bool> isDarkModeGlobal = ValueNotifier(false);

// ✅ FIX CHUẨN
final backGroundColor = CupertinoDynamicColor.withBrightness(
  color: Colors.white,
  darkColor: Color(0xFF1C1C1E),
);