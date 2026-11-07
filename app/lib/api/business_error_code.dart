/// 服务端业务错误码
abstract final class BusinessErrorCode {
  // 用户模块
  static const phoneRegistered = '1001';
  static const loginFailed = '1002';
  static const userDisabled = '1003';
  static const userNotFound = '1004';
  static const refreshTokenInvalid = '1005';

  // 设备认证模块
  static const deviceTokenInvalid = '1100';
  static const signMissing = '1101';
  static const timestampInvalid = '1102';
  static const signInvalid = '1103';
  static const nonceReplay = '1104';

  // 菜谱模块
  static const recipeNotFound = '1200';
  static const recipePoolEmpty = '1201';
}

/// 业务错误码兜底文案。
const Map<String, String> businessErrorMessage = {
  // 用户模块
  BusinessErrorCode.phoneRegistered: '手机号已被注册',
  BusinessErrorCode.loginFailed: '账号或密码错误',
  BusinessErrorCode.userDisabled: '账号已被禁用',
  BusinessErrorCode.userNotFound: '账号不存在',
  BusinessErrorCode.refreshTokenInvalid: 'refresh token 无效或已过期',

  // 设备认证模块
  BusinessErrorCode.deviceTokenInvalid: '设备令牌无效或已过期',
  BusinessErrorCode.signMissing: '缺少签名请求头',
  BusinessErrorCode.timestampInvalid: '请求时间戳超出允许窗口',
  BusinessErrorCode.signInvalid: '签名校验失败',
  BusinessErrorCode.nonceReplay: '请求已被使用，疑似重放',

  // 菜谱模块
  BusinessErrorCode.recipeNotFound: '菜谱不存在或已下架',
  BusinessErrorCode.recipePoolEmpty: '没有符合筛选条件的菜谱，试试放宽筛选',
};
