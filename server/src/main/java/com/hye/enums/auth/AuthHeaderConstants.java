package com.hye.enums.auth;

/**
 * 认证相关请求头名称。
 */
public final class AuthHeaderConstants {

    /**
     * 握手凭证请求头。
     */
    public static final String APP_KEY = "X-App-Key";

    /**
     * 设备访问令牌请求头。
     */
    public static final String ACCESS_TOKEN = "X-Access-Token";

    /**
     * 请求时间戳请求头。
     */
    public static final String TIMESTAMP = "X-Timestamp";

    /**
     * 一次性随机数请求头。
     */
    public static final String NONCE = "X-Nonce";

    /**
     * 请求签名请求头。
     */
    public static final String SIGN = "X-Sign";

    private AuthHeaderConstants() {
    }
}
