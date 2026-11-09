package com.hye.enums.exception;

import com.hye.common.enums.exception.ErrorCode;
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
    DEVICE_TOKEN_INVALID("1100", "设备令牌无效或已过期"),
    SIGN_MISSING("1101", "缺少签名请求头"),
    TIMESTAMP_INVALID("1102", "请求时间戳超出允许窗口"),
    SIGN_INVALID("1103", "签名校验失败"),
    NONCE_REPLAY("1104", "请求已被使用，疑似重放"),
    
    // 菜谱模块
    RECIPE_NOT_FOUND("1200", "菜谱不存在或已下架"),
    RECIPE_POOL_EMPTY("1201", "没有符合筛选条件的菜谱，试试放宽筛选"),

    // 餐厅模块
    RESTAURANT_POOL_EMPTY("1301", "附近没有符合条件的餐厅，试试扩大距离或取消筛选"),
    RESTAURANT_QUERY_FAILED("1302", "附近餐厅获取失败，请稍后重试"),
    RESTAURANT_CUISINE_EMPTY("1303", "附近没有合适的菜系"),
    RESTAURANT_NOT_FOUND("1304", "餐厅不存在"),
    ;

    private final String code;
    private final String msg;
}
