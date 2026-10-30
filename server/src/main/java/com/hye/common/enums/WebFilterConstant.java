package com.hye.common.enums;

import org.springframework.core.Ordered;

/**
 * Web 过滤器链顺序常量。
 *
 * <p>执行顺序：跨域 → 请求体缓存 → 签名鉴权。</p>
 */
public interface WebFilterConstant {

    /**
     * 跨域
     */
    int CORS_FILTER_ORDER = Ordered.HIGHEST_PRECEDENCE;

    /**
     * 请求体缓存
     */
    int CACHED_BODY_FILTER_ORDER = Ordered.HIGHEST_PRECEDENCE + 1;

    /**
     * 签名鉴权
     */
    int SIGN_AUTH_FILTER_ORDER = Ordered.HIGHEST_PRECEDENCE + 2;
}
