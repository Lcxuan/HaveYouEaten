package com.hye.redis.auth;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * 认证相关 Redis 操作：key 前缀定义与读写封装。
 */
@Component
public class AuthRedisKey {

    /**
     * 访问令牌 key 前缀，完整 key 为 auth:token:{token}。
     */
    public static final String TOKEN_KEY_PREFIX = "auth:token:";

    /**
     * nonce 防重放 key 前缀，完整 key 为 auth:nonce:{nonce}。
     */
    public static final String NONCE_KEY_PREFIX = "auth:nonce:";

    /**
     * 用户登录 refresh token key 前缀，完整 key 为 auth:refresh:{refreshToken}。
     */
    public static final String REFRESH_TOKEN_KEY_PREFIX = "auth:refresh:";

    private final StringRedisTemplate stringRedisTemplate;

    public AuthRedisKey(StringRedisTemplate stringRedisTemplate) {
        this.stringRedisTemplate = stringRedisTemplate;
    }

    /**
     * 保存用户 refresh token 并设置有效期。
     *
     * @param refreshToken 刷新令牌
     * @param userId       用户 id
     * @param ttl          有效期
     */
    public void setRefreshToken(String refreshToken, Long userId, Duration ttl) {
        stringRedisTemplate.opsForValue().set(REFRESH_TOKEN_KEY_PREFIX + refreshToken, String.valueOf(userId), ttl);
    }

    /**
     * 读取 refresh token 对应的用户 id。
     *
     * @param refreshToken 刷新令牌
     * @return 用户 id，不存在或已过期返回 null
     */
    public String getRefreshTokenUserId(String refreshToken) {
        return stringRedisTemplate.opsForValue().get(REFRESH_TOKEN_KEY_PREFIX + refreshToken);
    }

    /**
     * 删除 refresh token（轮换时作废旧令牌）。
     *
     * @param refreshToken 刷新令牌
     */
    public void deleteRefreshToken(String refreshToken) {
        stringRedisTemplate.delete(REFRESH_TOKEN_KEY_PREFIX + refreshToken);
    }
}
