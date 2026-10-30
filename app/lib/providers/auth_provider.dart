import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/api/api_exception.dart';
import 'package:have_you_eaten/storage/auth_storage.dart';
import 'package:have_you_eaten/repositories/auth_repository.dart';

/// 认证仓库 Provider。
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const AuthRepository(),
);

/// 登录态：loading 初始化中；nickname 非空视为已登录。
class AuthState {
  const AuthState({this.loading = false, this.nickname});

  final bool loading;
  final String? nickname;

  bool get loggedIn => nickname != null;
}

/// 认证状态管理：启动恢复、登录、注册、登出。
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthState(loading: true);
  }

  /// 启动时从安全存储恢复登录态。
  Future<void> _restore() async {
    final tokens = await AuthStorage.readUserTokens();
    final profile = await AuthStorage.readUserProfile();
    state = tokens.refreshToken != null
        ? AuthState(nickname: profile.nickname)
        : const AuthState();
  }

  /// 登录：成功后刷新状态，失败原样抛 [ApiException] 供 UI 提示。
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    await ref.read(authRepositoryProvider).login(phone: phone, password: password);
    state = AuthState(nickname: (await AuthStorage.readUserProfile()).nickname);
  }

  /// 注册：注册成功即自动登录。
  Future<void> register({
    required String phone,
    required String password,
    String? nickname,
  }) async {
    await ref.read(authRepositoryProvider).register(
      phone: phone,
      password: password,
      nickname: nickname,
    );
    state = AuthState(nickname: (await AuthStorage.readUserProfile()).nickname);
  }

  /// 登出：清除本地登录态（服务端令牌自然过期）。
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// 统一提取异常文案，供页面 SnackBar 提示。
String friendlyError(Object error) {
  if (error is DioException) {
    // 业务错误：后端返回的 code/msg
    if (error.error is ApiException) {
      return (error.error as ApiException).message;
    }
    // 连接层错误：给出具体原因便于排查
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '连接超时，请确认后端服务已启动';
      case DioExceptionType.connectionError:
        return '无法连接服务器 ${error.requestOptions.uri.host}:${error.requestOptions.uri.port}'
            '${error.message == null ? '' : '（${error.message}）'}';
      default:
        return '网络错误：${error.message ?? error.type.name}';
    }
  }
  if (error is ApiException) {
    return error.message;
  }
  // 兜底：打印完整异常（含堆栈）便于定位，同时向用户展示真实类型与内容
  debugPrint('未处理的异常: ${error.runtimeType}\n$error');
  return '网络异常，请稍后重试！';
}
