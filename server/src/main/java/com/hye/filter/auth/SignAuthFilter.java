package com.hye.filter.auth;

import com.hye.common.utils.SignUtils;
import com.hye.config.AuthProperties;
import com.hye.enums.auth.AuthHeaderConstants;
import com.hye.enums.exception.BusinessErrorCodeConstants;
import com.hye.redis.auth.AuthRedis;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

/**
 * 签名鉴权过滤器：依次校验 token、时间窗、HMAC 签名、nonce 防重放，全部通过才放行。
 *
 * <p>握手接口和开发模式不校验；请求体由 CachedBodyFilter 提前缓存，读完后 Controller 仍可再读。</p>
 */
@Slf4j
public class SignAuthFilter extends OncePerRequestFilter {

    private static final String HANDSHAKE_PATH = "/api/auth/handshake";

    private final AuthProperties authProperties;

    private final AuthRedis authRedis;

    public SignAuthFilter(AuthProperties authProperties, AuthRedis authRedis) {
        this.authProperties = authProperties;
        this.authRedis = authRedis;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // 开发模式（凭证留空）或非业务接口、握手接口、预检请求不校验
        return !authProperties.enabled()
                || !request.getRequestURI().startsWith("/api/")
                || HANDSHAKE_PATH.equals(request.getRequestURI())
                || "OPTIONS".equalsIgnoreCase(request.getMethod());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        // 1. token 有效性：Redis 中存在即有效（过期由 TTL 自动清理）
        String token = resolveToken(request);
        if (token == null) {
            reject(response, BusinessErrorCodeConstants.DEVICE_TOKEN_INVALID.getCode(), "缺少设备令牌");
            return;
        }
        Boolean tokenExists;
        try {
            tokenExists = authRedis.hasDeviceToken(token);
        } catch (Exception e) {
            log.error("鉴权 Redis 访问失败", e);
            reject(response, "500", "鉴权服务异常");
            return;
        }
        if (!Boolean.TRUE.equals(tokenExists)) {
            reject(response, BusinessErrorCodeConstants.DEVICE_TOKEN_INVALID.getCode(),
                    BusinessErrorCodeConstants.DEVICE_TOKEN_INVALID.getMsg());
            return;
        }

        // 2. 时间戳窗口
        String timestamp = request.getHeader(AuthHeaderConstants.TIMESTAMP);
        String nonce = request.getHeader(AuthHeaderConstants.NONCE);
        String sign = request.getHeader(AuthHeaderConstants.SIGN);
        if (!StringUtils.hasText(timestamp) || !StringUtils.hasText(nonce) || !StringUtils.hasText(sign)) {
            reject(response, BusinessErrorCodeConstants.SIGN_MISSING.getCode(),
                    BusinessErrorCodeConstants.SIGN_MISSING.getMsg());
            return;
        }
        if (!SignUtils.isTimestampValid(timestamp, authProperties.getTimestampWindowSeconds())) {
            reject(response, BusinessErrorCodeConstants.TIMESTAMP_INVALID.getCode(),
                    BusinessErrorCodeConstants.TIMESTAMP_INVALID.getMsg());
            return;
        }

        // 3. HMAC 签名比对（常量时间比较）；body 已由 CachedBodyFilter 缓存，可安全读取
        // multipart 上传的原始字节含随机 boundary，客户端无法稳定复现，故仅对非上传请求校验 body 摘要
        String contentType = request.getContentType();
        String body = contentType != null && contentType.toLowerCase().startsWith("multipart/")
                ? ""
                : new String(request.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        String stringToSign = SignUtils.buildStringToSign(
                request.getMethod(), request.getRequestURI(), request.getQueryString(),
                timestamp, nonce, SignUtils.sha256Hex(body));
        String expected = SignUtils.hmacSha256Hex(authProperties.getSignSecret(), stringToSign);
        if (!SignUtils.safeEquals(expected, sign)) {
            reject(response, BusinessErrorCodeConstants.SIGN_INVALID.getCode(),
                    BusinessErrorCodeConstants.SIGN_INVALID.getMsg());
            return;
        }

        // 4. nonce 防重放：SETNX 占位，占用失败即重复请求
        Boolean firstTime;
        try {
            firstTime = authRedis.trySetNonce(nonce,
                    Duration.ofSeconds(authProperties.getTimestampWindowSeconds() * 2));
        } catch (Exception e) {
            log.error("鉴权 Redis 访问失败", e);
            reject(response, "500", "鉴权服务异常");
            return;
        }
        if (!Boolean.TRUE.equals(firstTime)) {
            reject(response, BusinessErrorCodeConstants.NONCE_REPLAY.getCode(),
                    BusinessErrorCodeConstants.NONCE_REPLAY.getMsg());
            return;
        }

        filterChain.doFilter(request, response);
    }

    /**
     * 从请求头提取访问令牌，空白视为缺失。
     */
    private String resolveToken(HttpServletRequest request) {
        String token = request.getHeader(AuthHeaderConstants.ACCESS_TOKEN);
        if (token == null || token.isBlank()) {
            return null;
        }
        return token.trim();
    }

    /**
     * 以 HTTP 200 + JSON 业务码返回鉴权失败响应并终止请求。
     */
    private void reject(HttpServletResponse response, String code, String msg) throws IOException {
        response.setStatus(HttpStatus.OK.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write(
                "{\"code\":\"" + code + "\",\"msg\":\"" + msg + "\",\"data\":null}");
    }
}
