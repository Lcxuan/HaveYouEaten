import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:have_you_eaten/api/auth/auth_api.dart';
import 'package:have_you_eaten/api/user/user_api.dart';
import 'package:have_you_eaten/config/api_config.dart';
import 'package:have_you_eaten/api/api_exception.dart';
import 'package:have_you_eaten/storage/auth_storage.dart';
import 'package:have_you_eaten/utils/sign_util.dart';

/// 统一 API 客户端：请求签名、设备握手与用户双令牌自动续期。
///
/// 服务端固定返回 HTTP 200 + 业务码（code），本类统一处理三类透明重试：
/// - 1100 设备令牌失效 → 自动重新握手后重发一次；
/// - 401 用户未登录 → 自动用 refreshToken 轮换续期后重发一次；
/// - 其余业务码原样抛出 [ApiException] 交由 UI 提示。
class Request {
  Request._();

  static final Dio dio = _build();

  /// 进行中的刷新任务：并发收到多个 401 时只触发一次刷新。
  static Future<bool>? _refreshing;

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onResponse: _onResponse),
    );
    return dio;
  }

  /// 请求前：补设备令牌并附加签名四件套；已登录再附 Authorization。
  static Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.uri.path;
    final body = options.data == null ? '' : jsonEncode(options.data);
    final timestamp = SignUtil.currentTimestamp();
    final nonce = SignUtil.generateNonce();
    final sign = SignUtil.hmacSha256Hex(
      ApiConfig.signSecret,
      SignUtil.buildStringToSign(
        options.method,
        path,
        options.uri.query,
        timestamp,
        nonce,
        SignUtil.sha256Hex(body),
      ),
    );
    options.headers['X-Timestamp'] = timestamp;
    options.headers['X-Nonce'] = nonce;
    options.headers['X-Sign'] = sign;

    // 握手请求只带 App 凭证，不带设备令牌（由请求的 isHandshake 标记声明）。
    if (options.extra['isHandshake'] == true) {
      options.headers['X-App-Key'] = ApiConfig.appKey;
    } else {
      final deviceToken = await AuthStorage.readDeviceToken() ?? await AuthApi.handshake();
      options.headers['X-Access-Token'] = deviceToken;
      final accessToken = (await AuthStorage.readUserTokens()).accessToken;
      if (accessToken != null) {
        options.headers['Authorization'] = accessToken;
      }
    }
    handler.next(options);
  }

  /// 响应后：处理业务码，透明重试设备令牌与用户令牌失效场景。
  static Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final data = response.data;
    final code = data is Map ? data['code']?.toString() : null;
    if (code == null || code == '0') {
      handler.next(response);
      return;
    }

    final options = response.requestOptions;
    final msg = data is Map ? (data['msg']?.toString() ?? '请求失败') : '请求失败';

    // 设备令牌失效：重新握手后重发一次（握手请求自身除外）。
    if (code == '1100' &&
        options.extra['isHandshake'] != true &&
        options.extra['deviceRetried'] != true) {
      options.extra['deviceRetried'] = true;
      try {
        await AuthApi.handshake();
      } on DioException {
        return _reject(handler, code, msg, options);
      }
      return _retry(options, handler);
    }

    // 用户登录态失效：刷新令牌后重发一次（刷新请求自身除外）。
    if (code == '401' &&
        options.extra['isRefresh'] != true &&
        options.extra['authRetried'] != true) {
      options.extra['authRetried'] = true;
      final refreshed = await _refreshTokens();
      if (!refreshed) {
        return _reject(handler, code, msg, options);
      }
      return _retry(options, handler);
    }

    _reject(handler, code, msg, options);
  }

  /// 刷新用户双令牌（refresh 轮换）；失败清除登录态并返回 false。
  static Future<bool> _refreshTokens() {
    // 并发调用共享同一个刷新任务，避免 refresh token 被重复轮换。
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  static Future<bool> _doRefresh() async {
    final refreshToken = (await AuthStorage.readUserTokens()).refreshToken;
    if (refreshToken == null) {
      return false;
    }
    try {
      final session = await UserApi.refresh(refreshToken: refreshToken);
      await AuthStorage.writeUserTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return true;
    } on DioException {
      // refresh token 已失效（1005）：清除登录态，交由 UI 引导重新登录。
      await AuthStorage.clearUser();
      return false;
    }
  }

  /// 用新签名重发请求，并把结果交回拦截链。
  static Future<void> _retry(
    RequestOptions options,
    ResponseInterceptorHandler handler,
  ) async {
    final response = await dio.fetch(options);
    handler.resolve(response);
  }

  /// 把业务错误包装为 [ApiException] 抛出。
  static void _reject(
    ResponseInterceptorHandler handler,
    String code,
    String msg,
    RequestOptions options,
  ) {
    handler.reject(
      DioException(requestOptions: options, error: ApiException(code, msg)),
    );
  }
}

/// Result 结构解包：从服务端响应中提取 data 字段。
Map<String, dynamic> unwrapData(Response response) {
  final data = response.data;
  if (data is Map && data['data'] is Map) {
    return Map<String, dynamic>.from(data['data'] as Map);
  }
  return const {};
}
