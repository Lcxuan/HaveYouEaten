package com.hye.redis.auth;

import com.hye.config.AppProperties;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * 认证相关 Redis 操作：key 以应用名为前缀（hye.name），读写统一封装。
 */
@Component
public class AuthRedis {

    /**
     * 设备令牌 key 段，完整 key 为 {app}:auth:device-token:{token}。
     */
    private static final String DEVICE_TOKEN_KEY = "auth:device-token:";

    /**
     * nonce 防重放 key 段，完整 key 为 {app}:auth:nonce:{nonce}。
     */
    private static final String NONCE_KEY = "auth:nonce:";

    /**
     * 用户登录 refresh token key 段，完整 key 为 {app}:auth:refresh:{refreshToken}。
     */
    private static final String REFRESH_TOKEN_KEY = "auth:refresh:";

    private final String keyPrefix;

    private final StringRedisTemplate stringRedisTemplate;

    public AuthRedis(AppProperties appProperties, StringRedisTemplate stringRedisTemplate) {
        this.keyPrefix = appProperties.getName() + ":";
        this.stringRedisTemplate = stringRedisTemplate;
    }

    /**
     * 判断设备令牌是否有效（Redis 中存在即有效，过期由 TTL 自动清理）。
     *
     * @param token 设备令牌
     * @return 是否有效
     */
    public boolean hasDeviceToken(String token) {
        return Boolean.TRUE.equals(stringRedisTemplate.hasKey(keyPrefix + DEVICE_TOKEN_KEY + token));
    }

    /**
     * 保存设备令牌，TTL 到期自动失效。
     *
     * @param token 设备令牌
     * @param ttl   有效期
     */
    public void setDeviceToken(String token, Duration ttl) {
        stringRedisTemplate.opsForValue().set(keyPrefix + DEVICE_TOKEN_KEY + token, "1", ttl);
    }

    /**
     * nonce 防重放：首次写入占位成功返回 true，已占用（疑似重放）返回 false。
     *
     * @param nonce 一次性随机数
     * @param ttl  占位有效期
     * @return 是否首次使用
     */
    public boolean trySetNonce(String nonce, Duration ttl) {
        return Boolean.TRUE.equals(stringRedisTemplate.opsForValue()
                .setIfAbsent(keyPrefix + NONCE_KEY + nonce, "1", ttl));
    }

    /**
     * 保存用户 refresh token 并设置有效期。
     *
     * @param refreshToken 刷新令牌
     * @param userId       用户 id
     * @param ttl          有效期
     */
    public void setRefreshToken(String refreshToken, Long userId, Duration ttl) {
        stringRedisTemplate.opsForValue().set(key(REFRESH_TOKEN_KEY, refreshToken), String.valueOf(userId), ttl);
    }

    /**
     * 读取 refresh token 对应的用户 id。
     *
     * @param refreshToken 刷新令牌
     * @return 用户 id，不存在或已过期返回 null
     */
    public String getRefreshTokenUserId(String refreshToken) {
        return stringRedisTemplate.opsForValue().get(key(REFRESH_TOKEN_KEY, refreshToken));
    }

    /**
     * 删除 refresh token（轮换时作废旧令牌）。
     *
     * @param refreshToken 刷新令牌
     */
    public void deleteRefreshToken(String refreshToken) {
        stringRedisTemplate.delete(key(REFRESH_TOKEN_KEY, refreshToken));
    }

    /**
     * 拼接完整 key：{app}:{段}:{业务值}。
     */
    private String key(String segment, String value) {
        return keyPrefix + segment + value;
    }
}
