import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/views/auth/login_view.dart';
import 'package:have_you_eaten/views/auth/register_view.dart';
import 'package:have_you_eaten/views/home/home_view.dart';
import 'package:have_you_eaten/views/recipe/recipe_detail_view.dart';
import 'package:have_you_eaten/views/settings/blacklist_view.dart';

/// 负责创建 GoRouter 并集中维护路由表。
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // 固定路由
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeView(),
    ),
    // 认证模块
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterView(),
    ),
    // 菜谱详情
    GoRoute(
      path: '/recipe/:id',
      name: 'recipeDetail',
      builder: (context, state) =>
          RecipeDetailView(id: state.pathParameters['id'] ?? ''),
    ),
    // 黑名单管理
    GoRoute(
      path: '/settings/blacklist',
      name: 'blacklist',
      builder: (context, state) => const BlacklistView(),
    ),
  ],
  errorBuilder: (context, state) => _RouteErrorView(path: state.uri.path),
);

/// 未匹配路由时的兜底页面。
class _RouteErrorView extends StatelessWidget {
  const _RouteErrorView({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '页面不存在：$path',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
