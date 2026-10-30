import 'package:have_you_eaten/api/user/user_api.dart';
import 'package:have_you_eaten/api/api_exception.dart';
import 'package:have_you_eaten/storage/auth_storage.dart';
import 'package:have_you_eaten/api/user/response/login_response.dart';

/// 认证业务编排：调用用户接口并把会话写入安全存储。
class AuthRepository {
  const AuthRepository();

  /// 注册：成功后自动登录，保证双令牌就绪。
  Future<void> register({
    required String phone,
    required String password,
    String? nickname,
  }) async {
    final userId = await UserApi.register(
      phone: phone,
      password: password,
      nickname: nickname,
    );
    if (userId.isEmpty) {
      throw const ApiException('-1', '注册响应异常');
    }
    await login(phone: phone, password: password);
  }

  /// 手机号 + 密码登录，成功后保存双令牌与用户信息。
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    await _saveSession(
      await UserApi.login(phone: phone, password: password),
    );
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await UserApi.logout();
    } catch (_) {
      // 服务端登出失败（如网络异常）不阻断本地登出
    } finally {
      await AuthStorage.clearUser();
    }
  }

  /// 会话落库：令牌与用户信息写入安全存储。
  Future<void> _saveSession(LoginResponse session) async {
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
