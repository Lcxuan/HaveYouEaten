import 'package:dio/dio.dart';

import 'package:have_you_eaten/api/request.dart';
import 'package:have_you_eaten/storage/auth_storage.dart';

/// 设备认证接口。
class AuthApi {
  const AuthApi._();

  /// 设备握手：X-App-Key 换短期设备令牌并写入安全存储。
  ///
  /// isHandshake 标记告知拦截器：本请求不带设备令牌、失败时也不重试握手。
  static Future<String> handshake() async {
    final data = unwrapData(
      await Request.dio.post(
        '/api/auth/handshake',
        options: Options(extra: {'isHandshake': true}),
      ),
    );
    final token = data['token'] as String;
    await AuthStorage.writeDeviceToken(token);
    return token;
  }
}
