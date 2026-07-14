import 'package:beltech/core/theme/app_theme_dark.dart';
import 'package:beltech/core/theme/app_theme_light.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => buildDarkTheme();

  static ThemeData get lightTheme => buildLightTheme();
}
