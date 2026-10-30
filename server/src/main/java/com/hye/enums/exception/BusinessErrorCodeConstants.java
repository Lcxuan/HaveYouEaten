package com.hye.enums.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 业务错误码：各业务模块自定义，与全局通用错误码区分。
 */
@Getter
@RequiredArgsConstructor
public enum BusinessErrorCodeConstants implements ErrorCode {

    // 用户模块
    USER_PHONE_REGISTERED("1001", "手机号已被注册"),
    LOGIN_FAILED("1002", "账号或密码错误"),
    USER_DISABLED("1003", "账号已被禁用"),
    USER_NOT_FOUND("1004", "账号不存在"),
    REFRESH_TOKEN_INVALID("1005", "refresh token 无效或已过期"),

    // 设备认证模块
    DEVICE_TOKEN_INVALID("1100", "设备令牌无效或已过期");

    private final String code;
    private final String msg;
}
