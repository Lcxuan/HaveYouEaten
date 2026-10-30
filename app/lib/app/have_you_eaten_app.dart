import 'package:flutter/material.dart';

import 'package:have_you_eaten/app/app_router.dart';
import 'package:have_you_eaten/theme/app_theme.dart';

/// 配置应用主题和全局路由入口。
class HaveYouEatenApp extends StatelessWidget {
  const HaveYouEatenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '吃了吗？',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
