package com.hye.controller.auth.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Data;

/**
 * 握手响应结果。
 */
@Data
@Builder
@Schema(description = "握手响应")
public class AuthHandshakeVO {

    /**
     * 短期访问令牌，后续请求通过 X-Access-Token 请求头携带。
     */
    @Schema(description = "访问令牌")
    private String token;

    /**
     * 令牌有效期（秒）。
     */
    @Schema(description = "令牌有效期（秒）")
    private Long expiresIn;
}
