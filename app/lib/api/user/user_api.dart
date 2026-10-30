import 'package:dio/dio.dart';

import 'package:have_you_eaten/api/user/response/login_response.dart';
import 'package:have_you_eaten/api/request.dart';

/// 用户接口：注册、登录、刷新令牌。
class UserApi {
  const UserApi._();

  /// 注册：成功返回新用户 id。
  static Future<String> register({
    required String phone,
    required String password,
    String? nickname,
  }) async {
    final data = unwrapData(
      await Request.dio.post(
        '/api/user/register',
        data: {
          'phone': phone,
          'password': password,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
        },
      ),
    );
    return data['userId']?.toString() ?? '';
  }

  /// 手机号 + 密码登录，返回用户会话。
  static Future<LoginResponse> login({
    required String phone,
    required String password,
  }) async {
    return LoginResponse.fromJson(
      unwrapData(
        await Request.dio.post(
          '/api/user/login',
          data: {'phone': phone, 'password': password},
        ),
      ),
    );
  }

  /// 退出登录
  static Future<void> logout() async {
    await Request.dio.post('/api/user/logout');
  }

  /// 刷新令牌（refresh 轮换），返回新的用户会话。
  ///
  /// isRefresh 标记告知拦截器：本请求失败时不再触发刷新重试。
  static Future<LoginResponse> refresh({required String refreshToken}) async {
    return LoginResponse.fromJson(
      unwrapData(
        await Request.dio.post(
          '/api/user/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'isRefresh': true}),
        ),
      ),
    );
  }
}
