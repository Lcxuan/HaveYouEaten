import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:have_you_eaten/api/business_error_code.dart';
import 'package:have_you_eaten/api/error_code.dart';
import 'package:have_you_eaten/config/api_config.dart';
import 'package:have_you_eaten/utils/auth_storage.dart';
import 'package:have_you_eaten/utils/sign_util.dart';

/// 统一请求入口：配置、Dio 实例、签名拦截器与业务方法。
///
/// 服务端固定返回 HTTP 200 + 业务码（code），本类处理三类情况：
/// - 设备令牌失效（1100）→ 重新握手后重发一次；
/// - 用户登录失效（401）→ 用 refreshToken 续期后重发一次；
/// - 其余非成功码 / 网络异常 → 抛出 [ApiException]。
class Request {
  Request._();

  /// 请求根地址 = 服务地址 + 业务前缀。
  static const baseUrl = '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}';

  /// 默认请求超时时间。
  static const timeout = Duration(milliseconds: ApiConfig.requestTimeout);

  /// 默认请求体类型。
  static const contentType = 'application/json';

  /// HMAC-SHA256 签名密钥。
  static const _signSecret = ApiConfig.signSecret;

  /// 登录态彻底失效（refresh 失败或本地无 refreshToken）时回调。
  ///
  /// 由 `AuthNotifier` 注册，用于同步内存中的登录态。
  static void Function()? onUnauthorized;

  /// 令牌刷新成功回调，用于同步内存中的 session。
  static void Function(String accessToken, String refreshToken)?
  onTokensRefreshed;

  static final Dio _dio = _create();

  /// 在途请求，登出时统一取消。
  static final Set<CancelToken> _pending = <CancelToken>{};

  /// 进行中的握手/刷新任务：并发请求只触发一次。
  static Future<String>? _handshaking;
  static Future<bool>? _refreshing;

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        sendTimeout: timeout,
        receiveTimeout: timeout,
        contentType: contentType,
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
    if (ApiConfig.isDev) {
      dio.interceptors.add(_debugInterceptor());
    }
    return dio;
  }

  /// 开发期日志：只打印方法、地址与结果，不输出令牌等敏感头。
  static InterceptorsWrapper _debugInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[HTTP] -> ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
          '[HTTP] <- ${response.statusCode} ${response.requestOptions.uri}',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint(
          '[HTTP] !! ${error.requestOptions.method} '
          '${error.requestOptions.uri} ${error.type} ${error.error ?? ''}',
        );
        handler.next(error);
      },
    );
  }

  static Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    final token = _begin(cancelToken);
    return _request<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _options(
          headers: headers,
          timeout: timeout,
          responseType: responseType,
          extra: extra,
        ),
        cancelToken: token,
      ),
      token,
    );
  }

  static Future<T?> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    final token = _begin(cancelToken);
    return _request<T>(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(
          headers: headers,
          timeout: timeout,
          responseType: responseType,
          extra: extra,
        ),
        cancelToken: token,
      ),
      token,
    );
  }

  static Future<T?> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    final token = _begin(cancelToken);
    return _request<T>(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(
          headers: headers,
          timeout: timeout,
          responseType: responseType,
          extra: extra,
        ),
        cancelToken: token,
      ),
      token,
    );
  }

  static Future<T?> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    final token = _begin(cancelToken);
    return _request<T>(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(
          headers: headers,
          timeout: timeout,
          responseType: responseType,
          extra: extra,
        ),
        cancelToken: token,
      ),
      token,
    );
  }

  /// 文件上传：multipart 请求的 body 摘要由服务端跳过，签名仍覆盖路径与查询参数。
  static Future<T?> upload<T>(
    String path,
    FormData data, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    void Function(int count, int total)? onSendProgress,
  }) {
    final token = _begin(cancelToken);
    return _request<T>(
      () => _dio.post<dynamic>(
        path,
        data: data,
        options: _options(headers: headers, timeout: timeout),
        cancelToken: token,
        onSendProgress: onSendProgress,
      ),
      token,
    );
  }

  /// 返回完整 Result，适用于需要自行读取 code / msg 的场景。
  static Future<Response<dynamic>> getOriginal(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    final token = _begin(cancelToken);
    return _send(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _options(
          headers: headers,
          timeout: timeout,
          responseType: responseType,
          extra: extra,
        ),
        cancelToken: token,
      ),
      token,
    );
  }

  static Future<Response<dynamic>> postOriginal(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    final token = _begin(cancelToken);
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(
          headers: headers,
          timeout: timeout,
          responseType: responseType,
          extra: extra,
        ),
        cancelToken: token,
      ),
      token,
    );
  }

  static Future<Response<dynamic>> putOriginal(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    final token = _begin(cancelToken);
    return _send(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(
          headers: headers,
          timeout: timeout,
          responseType: responseType,
          extra: extra,
        ),
        cancelToken: token,
      ),
      token,
    );
  }

  static Future<Response<dynamic>> deleteOriginal(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    final token = _begin(cancelToken);
    return _send(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(
          headers: headers,
          timeout: timeout,
          responseType: responseType,
          extra: extra,
        ),
        cancelToken: token,
      ),
      token,
    );
  }

  /// 取消所有在途请求（登出时调用）。
  static void cancelAll([String reason = '用户已退出登录']) {
    for (final token in _pending.toList()) {
      if (!token.isCancelled) token.cancel(reason);
    }
    _pending.clear();
  }

  static Options _options({
    Map<String, dynamic>? headers,
    Duration? timeout,
    ResponseType? responseType,
    Map<String, dynamic>? extra,
  }) {
    return Options(
      headers: headers,
      sendTimeout: timeout,
      receiveTimeout: timeout,
      responseType: responseType,
      extra: extra,
    );
  }

  static CancelToken _begin(CancelToken? cancelToken) {
    final token = cancelToken ?? CancelToken();
    _pending.add(token);
    return token;
  }

  /// 提取 Result 的 data 字段。
  static Future<T?> _request<T>(
    Future<Response<dynamic>> Function() send,
    CancelToken token,
  ) async {
    final response = await _send(send, token);
    final body = response.data;
    if (body is Map) {
      return body['data'] as T?;
    }
    return null;
  }

  /// 把 DioException 统一转换成可展示的 [ApiException]。
  static Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() send,
    CancelToken token,
  ) async {
    try {
      return await send();
    } on DioException catch (error) {
      final cause = error.error;
      if (cause is ApiException) throw cause;
      throw ApiException(_resolveErrorCode(error), _resolveErrorMessage(error));
    } finally {
      _pending.remove(token);
    }
  }

  /// 请求前：补设备令牌、登录令牌并附加签名四件套。
  static Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _sign(options);

    try {
      // 握手请求只带 App 凭证，不带设备令牌。
      if (options.extra['isHandshake'] == true) {
        options.headers['X-App-Key'] = ApiConfig.appKey;
      } else {
        options.headers['X-Access-Token'] = await _ensureDeviceToken();
        final accessToken = await AuthStorage.readAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = accessToken;
        }
      }
    } on DioException catch (error) {
      handler.reject(error);
      return;
    } on ApiException catch (error) {
      handler.reject(_wrap(options, null, error));
      return;
    }

    if (options.method == 'GET') {
      options.headers['Cache-Control'] = 'no-cache';
      options.headers['Pragma'] = 'no-cache';
    }
    handler.next(options);
  }

  /// 附加签名四件套：时间戳、随机串、请求体摘要与 HMAC 签名。
  static void _sign(RequestOptions options) {
    final timestamp = SignUtil.currentTimestamp();
    final nonce = SignUtil.generateNonce();
    final sign = SignUtil.hmacSha256Hex(
      _signSecret,
      SignUtil.buildStringToSign(
        options.method,
        options.uri.path,
        options.uri.query,
        timestamp,
        nonce,
        SignUtil.sha256Hex(_encodeBody(options.data)),
      ),
    );
    options.headers['X-Timestamp'] = timestamp;
    options.headers['X-Nonce'] = nonce;
    options.headers['X-Sign'] = sign;
  }

  /// 请求体参与签名：与服务端读取的原始 body 保持一致。
  ///
  /// multipart 由服务端跳过 body 摘要，这里同样按空 body 计算。
  static String _encodeBody(dynamic data) {
    if (data == null || data is FormData) return '';
    if (data is String) return data;
    return jsonEncode(data);
  }

  /// 响应后：校验 Result 业务码，失效时透明重试一次。
  static Future<void> _onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final body = response.data;
    if (body == null) {
      handler.reject(
        _wrap(
          response.requestOptions,
          response,
          const ApiException('500', '请求没有返回值'),
        ),
      );
      return;
    }
    // 非 Result 结构（文件流等）直接放行。
    if (body is! Map) {
      handler.next(response);
      return;
    }

    final code = body['code']?.toString() ?? ErrorCode.success;
    if (code == ErrorCode.success) {
      handler.next(response);
      return;
    }

    final message = _resolveMessage(code, body['msg']?.toString());
    final options = response.requestOptions;

    // 设备令牌失效：重新握手后重发一次（握手请求自身除外）。
    if (code == BusinessErrorCode.deviceTokenInvalid &&
        options.extra['isHandshake'] != true &&
        options.extra['deviceRetried'] != true) {
      options.extra['deviceRetried'] = true;
      try {
        await AuthStorage.clearDeviceToken();
        options.headers['X-Access-Token'] = await _ensureDeviceToken();
      } on DioException catch (error) {
        handler.reject(error);
        return;
      } on ApiException catch (error) {
        handler.reject(_wrap(options, response, error));
        return;
      }
      await _retry(options, handler);
      return;
    }

    // 用户登录失效：刷新令牌后重发一次（刷新请求自身除外）。
    if (code == ErrorCode.unauthorized &&
        options.extra['isRefresh'] != true &&
        options.extra['authRetried'] != true) {
      options.extra['authRetried'] = true;
      if (!await _refreshTokens()) {
        handler.reject(_wrap(options, response, ApiException(code, message)));
        return;
      }
      final accessToken = await AuthStorage.readAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = accessToken;
      }
      await _retry(options, handler);
      return;
    }

    handler.reject(_wrap(options, response, ApiException(code, message)));
  }

  /// 业务码文案：服务端 msg 优先，其次错误码表，最后默认文案。
  static String _resolveMessage(String code, String? msg) {
    final text = msg?.trim();
    if (text != null && text.isNotEmpty) return text;
    return errorCode[code] ??
        businessErrorMessage[code] ??
        errorCode['default']!;
  }

  /// 设备令牌：优先读本地缓存，缺失时握手获取。
  static Future<String> _ensureDeviceToken() async {
    final cached = await AuthStorage.readDeviceToken();
    if (cached != null && cached.isNotEmpty) return cached;
    return _handshaking ??= _handshake().whenComplete(
      () => _handshaking = null,
    );
  }

  static Future<String> _handshake() async {
    final response = await _dio.post<dynamic>(
      '/auth/handshake',
      options: Options(extra: {'isHandshake': true}),
    );
    final body = response.data;
    final token = body is Map && body['data'] is Map
        ? body['data']['token']?.toString()
        : null;
    if (token == null || token.isEmpty) {
      throw const ApiException('500', '设备握手失败');
    }
    await AuthStorage.writeDeviceToken(token);
    return token;
  }

  /// 刷新用户双令牌（refresh 轮换）；失败时返回 false。
  static Future<bool> _refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  /// 执行一次刷新令牌请求。
  ///
  /// 使用 refreshToken 轮换双令牌：成功后写回本地并通知内存会话更新；
  /// 本地无 refreshToken、响应结构异常或服务端明确判定令牌失效时，
  /// 视为登录态不可恢复，触发 [onUnauthorized]。
  static Future<bool> _doRefresh() async {
    final refreshToken = await AuthStorage.readRefreshToken();
    // 本地已无凭证，无需再请求，直接通知全局登出。
    if (refreshToken == null || refreshToken.isEmpty) {
      await _notifyUnauthorized();
      return false;
    }
    try {
      final response = await _dio.post<dynamic>(
        '/user/refresh',
        data: {'refreshToken': refreshToken},
        // 标记刷新请求本身，避免其返回 401 时再次触发刷新造成递归。
        options: Options(extra: {'isRefresh': true}),
      );
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      // 响应结构不符合预期：无法取得新令牌，按登录失效处理。
      if (data is! Map) {
        await _notifyUnauthorized();
        return false;
      }
      final accessToken = data['accessToken']?.toString();
      final newRefreshToken = data['refreshToken']?.toString();
      // 双令牌必须同时返回，缺一不可，否则同样视为刷新失败。
      if (accessToken == null || newRefreshToken == null) {
        await _notifyUnauthorized();
        return false;
      }
      // 刷新成功后持久化新令牌（旧 refreshToken 已被服务端轮换作废）。
      await AuthStorage.writeUserTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      onTokensRefreshed?.call(accessToken, newRefreshToken);
      return true;
    } on DioException catch (error) {
      // 仅 refreshToken 明确失效时清登录态；网络异常保留凭证，允许重试。
      final cause = error.error;
      if (cause is ApiException &&
          (cause.code == BusinessErrorCode.refreshTokenInvalid ||
              cause.code == ErrorCode.unauthorized)) {
        await _notifyUnauthorized();
      }
      return false;
    }
  }

  /// 清除本地登录态并通知上层（跳转登录页、清空内存 session）。
  static Future<void> _notifyUnauthorized() async {
    await AuthStorage.clearUser();
    onUnauthorized?.call();
  }

  /// 用更新后的令牌重新发送请求。
  static Future<void> _retry(
    RequestOptions options,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      handler.resolve(await _dio.fetch(options));
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  /// 网络层异常：统一转成携带 [ApiException] 的 DioException。
  static void _onError(DioException error, ErrorInterceptorHandler handler) {
    // 业务码异常已由响应拦截器包装，保持原样。
    if (error.error is ApiException) {
      handler.next(error);
      return;
    }
    handler.reject(
      _wrap(
        error.requestOptions,
        error.response,
        ApiException(_resolveErrorCode(error), _resolveErrorMessage(error)),
        type: error.type,
      ),
    );
  }

  static DioException _wrap(
    RequestOptions options,
    Response<dynamic>? response,
    Exception exception, {
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    return DioException(
      requestOptions: options,
      response: response,
      type: type,
      error: exception,
    );
  }

  static String _resolveErrorCode(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) return '$statusCode';
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'timeout',
      DioExceptionType.connectionError => 'network',
      DioExceptionType.cancel => 'cancel',
      _ => 'unknown',
    };
  }

  static String _resolveErrorMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '请求超时，请稍后重试',
      DioExceptionType.connectionError => '网络连接失败，请检查网络设置',
      DioExceptionType.badCertificate => '证书校验失败，无法建立安全连接',
      DioExceptionType.cancel => '请求已取消',
      DioExceptionType.badResponse => _messageFromStatus(
        error.response?.statusCode,
      ),
      _ => '网络请求失败，请稍后重试',
    };
  }

  static String _messageFromStatus(int? statusCode) {
    if (statusCode == null) return errorCode['default']!;
    return errorCode['$statusCode'] ?? '请求失败（HTTP $statusCode）';
  }
}
