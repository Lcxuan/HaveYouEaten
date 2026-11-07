/// 通用错误码常量，供业务逻辑判断使用。
///
/// 与 [errorCode] 区分：这里只定义码值，文案表负责展示内容。
abstract final class ErrorCode {
  /// 接口成功码（与后端 GlobalErrorCodeConstants.SUCCESS 一致）。
  static const success = '0';

  static const badRequest = '400';
  static const unauthorized = '401';
  static const forbidden = '403';
  static const notFound = '404';
  static const methodNotAllowed = '405';
  static const serverError = '500';
}

/// HTTP / 业务码兜底文案，对照 yudao 的 `src/config/axios/errorCode.ts`。
///
/// 服务端返回 msg 时优先使用 msg，缺失才用这里的兜底值。
const Map<String, String> errorCode = {
  ErrorCode.badRequest: '请求参数错误',
  ErrorCode.unauthorized: '未登录或登录已失效',
  ErrorCode.forbidden: '无权限访问',
  ErrorCode.notFound: '资源不存在',
  ErrorCode.methodNotAllowed: '请求方法不支持',
  ErrorCode.serverError: '系统异常',
  'default': '系统未知错误，请反馈给管理员',
};

/// 统一的接口异常：业务码非成功、网络异常、超时等都会被包装成它。
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  /// 业务码或网络错误标识（timeout / network / cancel / unknown）。
  final String code;

  /// 可直接展示给用户的错误信息。
  final String message;

  @override
  String toString() => message;
}
