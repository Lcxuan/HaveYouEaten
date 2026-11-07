import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/config/api_config.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/routes/index.dart';

void main() {
  // 先初始化 Flutter，再挂载全局 ProviderScope，供页面共享状态。
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HaveYouEatenApp()));
}

/// 应用根组件：只负责主题与路由装配。
class HaveYouEatenApp extends StatelessWidget {
  const HaveYouEatenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: ApiConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
