import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 请求签名工具：与服务端 SignUtils 的算法保持一致。
///
/// stringToSign = METHOD\nPATH\nQUERY\nTIMESTAMP\nNONCE\nSHA256(BODY)，
/// 签名 = HMAC-SHA256(SIGN_SECRET, stringToSign) 的十六进制小写。
class SignUtil {
  const SignUtil._();

  /// 计算字符串的 SHA-256 十六进制（小写）。
  static String sha256Hex(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// 计算 HMAC-SHA256 十六进制（小写）。
  static String hmacSha256Hex(String secret, String message) {
    final hmacSha256 = Hmac(sha256, utf8.encode(secret));
    return hmacSha256.convert(utf8.encode(message)).toString();
  }

  /// 生成签名待串。
  static String buildStringToSign(
    String method,
    String path,
    String query,
    String timestamp,
    String nonce,
    String bodySha256,
  ) {
    return [method, path, query, timestamp, nonce, bodySha256].join('\n');
  }

  /// 生成一次性随机数（32 位十六进制，等效服务端 UUID.hex）。
  static String generateNonce() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// 当前毫秒级时间戳字符串。
  static String currentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
