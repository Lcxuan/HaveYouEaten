package com.hye.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * refresh token 配置：从 sa-token.refresh-timeout 读取有效期。
 *
 * <p>sa-token 前缀由 Sa-Token starter 绑定其官方配置，此处为自定义扩展属性，
 * 两者互不影响（未知属性默认忽略）。</p>
 */
@Data
@Component
@ConfigurationProperties(prefix = "sa-token")
public class RefreshTokenProperties {

    /**
     * refresh token 有效期（秒），默认 30 天。
     */
    private long refreshTimeout = 30 * 24 * 3600L;

    /**
     * 转为 Duration，便于直接设置 Redis TTL。
     */
    public Duration getRefreshTimeoutDuration() {
        return Duration.ofSeconds(refreshTimeout);
    }
}
