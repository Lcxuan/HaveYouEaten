package com.hye.controller.auth.dto;

import com.hye.common.annotation.HeaderBindField;
import com.hye.enums.auth.AuthHeaderConstants;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 握手请求参数，字段通过请求头自动装配。
 */
@Data
@Schema(description = "握手请求")
public class AuthHandshakeDTO {

    /**
     * 握手凭证：App 预置。
     */
    @HeaderBindField(AuthHeaderConstants.APP_KEY)
    @Schema(description = "握手凭证（X-App-Key 请求头）")
    private String appKey;

    /**
     * 请求时间戳（毫秒），用于防重放时间窗校验。
     */
    @HeaderBindField(AuthHeaderConstants.TIMESTAMP)
    @Schema(description = "请求时间戳（毫秒，X-Timestamp 请求头）")
    private String timestamp;

    /**
     * 一次性随机数，用于防重放。
     */
    @HeaderBindField(AuthHeaderConstants.NONCE)
    @Schema(description = "一次性随机数（X-Nonce 请求头）")
    private String nonce;
}
