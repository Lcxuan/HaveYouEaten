package com.hye.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * 鉴权配置：动态 Token + 请求签名（自用版加强方案）。
 *
 * <p>APP_KEY 用于启动握手换取短期 token；SIGN_SECRET 用于 HMAC 请求签名，
 * 两端预置、永不上网络传输。两者任一留空则整体退化为开发模式（不校验）。</p>
 */
@Data
@Component
@ConfigurationProperties(prefix = "hye.security")
public class AuthProperties {

    /**
     * 握手凭证：App 预置，POST /api/auth/handshake 时通过 X-App-Key 上送。
     */
    private String appKey;

    /**
     * HMAC-SHA256 签名密钥：App 与服务端共享。
     */
    private String signSecret;

    /**
     * 签发的 access token 有效期（秒），默认 2 小时。
     */
    private long tokenTtlSeconds = 7200;

    /**
     * 请求时间戳允许窗口（秒），默认 ±300 秒。
     */
    private long timestampWindowSeconds = 300;

    /**
     * 鉴权是否启用。
     */
    public boolean enabled() {
        return StringUtils.hasText(appKey) && StringUtils.hasText(signSecret);
    }
}
