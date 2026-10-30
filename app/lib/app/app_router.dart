import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/app/app_shell.dart';
import 'package:have_you_eaten/features/auth/screens/login_screen.dart';
import 'package:have_you_eaten/features/auth/screens/register_screen.dart';
import 'package:have_you_eaten/features/favorites/screens/favorites_screen.dart';
import 'package:have_you_eaten/features/history/screens/history_screen.dart';
import 'package:have_you_eaten/features/home/screens/home_screen.dart';
import 'package:have_you_eaten/features/settings/screens/settings_screen.dart';

/// 全局共享一个路由器实例，避免应用重建时重置导航栈。
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 底部导航壳：四个标签分支各自保留导航状态。
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        // 首页（转盘抽签）
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteNames.home,
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // 吃过记录
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteNames.history,
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        // 收藏
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteNames.favorites,
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
        // 设置
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteNames.settings,
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // 登录与注册放在根导航器上，覆盖底部导航栏。
    GoRoute(
      name: AppRouteNames.login,
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: AppRouteNames.register,
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);

/// 应用内命名路由的统一标识，供路由表和页面跳转共同使用。
abstract final class AppRouteNames {
  static const home = 'home';
  static const history = 'history';
  static const favorites = 'favorites';
  static const settings = 'settings';
  static const login = 'login';
  static const register = 'register';
}
