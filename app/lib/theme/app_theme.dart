import 'package:flutter/material.dart';

class AppTheme {
  /// App 的基础色板（对应原型图 design tokens），后续页面颜色优先从这里复用。
  static const persimmon = Color(0xFFFF6B35); // 柿橙 · 主行动色
  static const yolk = Color(0xFFFFB627); // 蛋黄 · 转盘高亮
  static const scallion = Color(0xFF4C9F70); // 葱绿 · 在家吃模式
  static const chili = Color(0xFFD7263D); // 辣红 · 指针 / 抽中提示
  static const ink = Color(0xFF2D1E12); // 深棕 · 正文
  static const paper = Color(0xFFFFF9F0); // 米白 · 餐瓷底色
  static const canvas = Color(0xFFF6EEE2); // 暖米 · 页面背景

  /// 全局 Material 3 主题，集中维护背景、主色和卡片样式。
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: persimmon,
      primary: persimmon,
      surface: paper,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: persimmon.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? persimmon : ink,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? persimmon : ink,
        ),
      ),
    ),
  );
}
