package com.hye.service.auth.impl;

import cn.hutool.core.util.IdUtil;
import com.hye.config.AuthProperties;
import com.hye.controller.auth.dto.AuthHandshakeDTO;
import com.hye.controller.auth.vo.AuthHandshakeVO;
import com.hye.enums.exception.BusinessException;
import com.hye.enums.exception.GlobalErrorCodeConstants;
import com.hye.common.utils.SignUtils;
import com.hye.redis.auth.AuthRedis;
import com.hye.service.auth.AuthService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Duration;

/**
 * 认证业务实现：握手凭证校验与短期令牌签发。
 */
@Slf4j
@Service
public class AuthServiceImpl implements AuthService {

    @Resource
    private AuthProperties authProperties;

    @Resource
    private AuthRedis authRedis;

    @Override
    public AuthHandshakeVO handshake(AuthHandshakeDTO dto) {
        if (!authProperties.enabled()) {
            throw new BusinessException(GlobalErrorCodeConstants.BAD_REQUEST, "服务端未启用鉴权");
        }
        if (!SignUtils.safeEquals(authProperties.getAppKey(), dto.getAppKey())) {
            throw new BusinessException(GlobalErrorCodeConstants.UNAUTHORIZED, "App Key 无效");
        }
        if (!SignUtils.isTimestampValid(dto.getTimestamp(), authProperties.getTimestampWindowSeconds())) {
            throw new BusinessException(GlobalErrorCodeConstants.UNAUTHORIZED, "请求时间戳超出允许窗口");
        }
        if (!StringUtils.hasText(dto.getNonce())) {
            throw new BusinessException(GlobalErrorCodeConstants.BAD_REQUEST, "缺少 nonce");
        }
        occupyNonce(dto.getNonce());
        return AuthHandshakeVO.builder()
                .token(issueToken())
                .expiresIn(authProperties.getTokenTtlSeconds())
                .build();
    }

    /**
     * nonce 占位防重放：SETNX 成功即首次使用，已存在视为重放。
     */
    private void occupyNonce(String nonce) {
        Boolean firstTime;
        try {
            firstTime = authRedis.trySetNonce(nonce,
                    Duration.ofSeconds(authProperties.getTimestampWindowSeconds() * 2));
        } catch (Exception e) {
            log.error("握手 nonce 占位失败", e);
            throw new BusinessException(GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR, "鉴权服务异常");
        }
        if (!Boolean.TRUE.equals(firstTime)) {
            throw new BusinessException(GlobalErrorCodeConstants.UNAUTHORIZED, "请求已被使用，疑似重放");
        }
    }

    /**
     * 生成随机令牌并写入 Redis，TTL 到期自动失效。
     */
    private String issueToken() {
        String token = IdUtil.fastSimpleUUID();
        try {
            authRedis.setDeviceToken(token, Duration.ofSeconds(authProperties.getTokenTtlSeconds()));
        } catch (Exception e) {
            log.error("握手写入 token 失败", e);
            throw new BusinessException(GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR, "鉴权服务异常");
        }
        return token;
    }
}
