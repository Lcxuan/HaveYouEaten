import 'package:flutter/foundation.dart';

/// 后端接口与凭证配置。
///
/// 值通过构建参数注入（等同 Vue 的 .env）：
/// - `flutter run --dart-define-from-file=config/config_dev.json`
/// - `flutter build apk --dart-define-from-file=config/config_prod.json`
///
/// 各环境文件位于 config/ 目录；未传参时使用 defaultValue 的开发兜底值。
class ApiConfig {
  /// 后端地址
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.1:8080',
  );

  /// 握手凭证：POST /api/auth/handshake 时通过 X-App-Key 上送。
  static const appKey = String.fromEnvironment('APP_KEY');

  /// HMAC-SHA256 签名密钥：App 与服务端共享。
  static const signSecret = String.fromEnvironment('SIGN_SECRET');

  /// 应用版本号：配置文件 version 字段，未配置时兜底 pubspec 版本。
  static const appVersion = String.fromEnvironment(
    'version',
    defaultValue: '0.1.0',
  );

  /// 当前是否为开发环境（方便日志开关等场景判断）。
  static bool get isDev => kDebugMode;
}
