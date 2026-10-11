import 'package:flutter/material.dart';

/// 对照 ui.html：iOS 浅色、灰底白卡、蓝色强调。
class AppColors {
  const AppColors._();

  static const scaffold = Color(0xFFF2F2F7);
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFF007AFF);
  static const text = Color(0xFF000000);
  static const secondary = Color(0xFF8E8E93);
  static const separator = Color(0xFFE5E5EA);
  static const placeholder = Color(0xFFC7C7CC);
  static const chipBg = Color(0x28787880);
  static const fieldBg = Color(0xFFF7F7F9);
}

class AppSizes {
  const AppSizes._();

  static const cardRadius = 12.0;
  static const tileMinHeight = 50.0;
  static const tilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const hMargin = 16.0;
}

final ThemeData appTheme = ThemeData(
  useMaterial3: false,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.scaffold,
  colorScheme: const ColorScheme.light(primary: AppColors.accent),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.accent),
);
