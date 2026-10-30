import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

/// 登录成功 / 刷新令牌后的用户会话。
@freezed
sealed class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String userId,
    required String nickname,
    required String accessToken,
    required String refreshToken,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> map) =>
      _$LoginResponseFromJson(map);
}
