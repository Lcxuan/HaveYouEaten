import 'package:have_you_eaten/api/request.dart';
import 'package:have_you_eaten/api/user/response/login_session.dart';

/// 用户接口：注册、登录、退出登录。
class UserApi {
  UserApi._();

  /// 注册：成功返回新用户 id。
  static Future<String> register({
    required String phone,
    required String password,
    String? nickname,
  }) async {
    final data = await Request.post<Map<String, dynamic>>(
      '/user/register',
      data: {
        'phone': phone,
        'password': password,
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      },
    );
    return data?['userId']?.toString() ?? '';
  }

  /// 手机号 + 密码登录，返回用户会话。
  static Future<LoginSession> login({
    required String phone,
    required String password,
  }) async {
    final data = await Request.post<Map<String, dynamic>>(
      '/user/login',
      data: {'phone': phone, 'password': password},
    );
    return LoginSession.fromJson(data ?? const {});
  }

  /// 退出登录（服务端令牌自然过期，本地状态由 store 清理）。
  static Future<void> logout() async {
    await Request.post<void>('/user/logout');
  }
}
