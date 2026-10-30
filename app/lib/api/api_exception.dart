/// 业务异常：携带服务端 Result 的 code 与 msg，供 UI 层提示。
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  /// 服务端业务码，如 0 成功 / 401 未登录 / 1005 刷新令牌失效。
  final String code;

  /// 错误提示文案。
  final String message;

  @override
  String toString() => 'ApiException($code, $message)';
}
