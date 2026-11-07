import 'package:have_you_eaten/api/error_code.dart';

/// 把请求层异常转为可直接展示给用户的文案。
String friendlyError(Object? error) {
  if (error is ApiException) return error.message;
  return '网络异常，请稍后重试！';
}
