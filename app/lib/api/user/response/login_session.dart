/// 登录成功 / 刷新令牌后的用户会话。
class LoginSession {
  const LoginSession({
    required this.userId,
    required this.nickname,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginSession.fromJson(Map<String, dynamic> json) {
    return LoginSession(
      userId: json['userId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }

  final String userId;
  final String nickname;
  final String accessToken;
  final String refreshToken;

  /// 令牌刷新后同步内存中的会话。
  LoginSession copyWith({
    String? userId,
    String? nickname,
    String? accessToken,
    String? refreshToken,
  }) {
    return LoginSession(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
