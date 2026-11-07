import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/api/request.dart';
import 'package:have_you_eaten/api/user/response/login_session.dart';
import 'package:have_you_eaten/api/user/user_api.dart';
import 'package:have_you_eaten/utils/auth_storage.dart';

/// 登录态：loading 为启动恢复中；session 非空视为已登录。
class AuthState {
  const AuthState({this.loading = false, this.session});

  final bool loading;
  final LoginSession? session;

  bool get loggedIn => session != null;
}

/// 认证状态管理：启动恢复、登录、注册、退出。
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 请求层登录失效 / 令牌刷新后，同步内存中的登录态。
    Request.onUnauthorized = _handleUnauthorized;
    Request.onTokensRefreshed = _handleTokensRefreshed;
    _restore();
    return const AuthState(loading: true);
  }

  void _handleUnauthorized() {
    state = const AuthState();
  }

  void _handleTokensRefreshed(String accessToken, String refreshToken) {
    final session = state.session;
    if (session == null) return;
    state = AuthState(
      session: session.copyWith(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
    );
  }

  /// 启动时从安全存储恢复登录态。
  Future<void> _restore() async {
    final tokens = await AuthStorage.readUserTokens();
    final profile = await AuthStorage.readUserProfile();
    state = tokens.refreshToken == null
        ? const AuthState()
        : AuthState(
            session: LoginSession(
              userId: profile.userId ?? '',
              nickname: profile.nickname ?? '',
              accessToken: tokens.accessToken ?? '',
              refreshToken: tokens.refreshToken!,
            ),
          );
  }

  /// 登录成功后保存会话。
  Future<void> login({required String phone, required String password}) async {
    final session = await UserApi.login(phone: phone, password: password);
    await _saveSession(session);
    state = AuthState(session: session);
  }

  /// 注册成功后自动登录。
  Future<void> register({
    required String phone,
    required String password,
    String? nickname,
  }) async {
    await UserApi.register(
      phone: phone,
      password: password,
      nickname: nickname,
    );
    await login(phone: phone, password: password);
  }

  /// 退出登录：服务端失败也继续清理本地登录态。
  Future<void> logout() async {
    try {
      await UserApi.logout();
    } catch (_) {
      // 网络异常不阻断本地登出。
    } finally {
      Request.cancelAll();
      await AuthStorage.clearUser();
      state = const AuthState();
    }
  }

  Future<void> _saveSession(LoginSession session) async {
    await AuthStorage.writeUserTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await AuthStorage.writeUserProfile(
      userId: session.userId,
      nickname: session.nickname,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
