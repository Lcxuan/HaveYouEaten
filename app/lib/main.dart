import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/app/have_you_eaten_app.dart';

void main() {
  // 先初始化 Flutter，再挂载全局 ProviderScope，供各页面共享状态与数据依赖。
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HaveYouEatenApp()));
}
