import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 鉴权凭证安全存储：设备令牌与用户双令牌。
class AuthStorage {
  const AuthStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _deviceTokenKey = 'device_token';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _nicknameKey = 'nickname';

  static Future<String?> readDeviceToken() =>
      _storage.read(key: _deviceTokenKey);

  static Future<void> writeDeviceToken(String token) =>
      _storage.write(key: _deviceTokenKey, value: token);

  /// 读取登录令牌对；refreshToken 为空视为未登录。
  static Future<({String? accessToken, String? refreshToken})> readUserTokens() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    return (accessToken: accessToken, refreshToken: refreshToken);
  }

  /// 保存登录令牌对（refresh 轮换后整体覆盖）。
  static Future<void> writeUserTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<({String? userId, String? nickname})> readUserProfile() async {
    final userId = await _storage.read(key: _userIdKey);
    final nickname = await _storage.read(key: _nicknameKey);
    return (userId: userId, nickname: nickname);
  }

  static Future<void> writeUserProfile({
    required String userId,
    required String nickname,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _nicknameKey, value: nickname);
  }

  /// 清除用户登录态（登出或 refresh 失效），设备令牌保留。
  static Future<void> clearUser() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _nicknameKey);
  }
}
