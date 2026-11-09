package com.hye.framework.amap.exception;

import com.hye.common.enums.exception.ErrorCode;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 高德组件错误码。
 */
@Getter
@RequiredArgsConstructor
public enum AmapErrorCodeConstants implements ErrorCode {

    UNAVAILABLE("1000", "高德服务未配置"),
    QUERY_FAILED("1001", "高德服务请求失败，请稍后重试");

    private final String code;
    private final String msg;
}