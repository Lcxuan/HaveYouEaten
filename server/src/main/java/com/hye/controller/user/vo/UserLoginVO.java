package com.hye.controller.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Data;

/**
 * 登录响应结果。
 */
@Data
@Builder
@Schema(description = "登录响应")
public class UserLoginVO {

    /**
     * 用户 id。
     */
    @Schema(description = "用户 id")
    private Long userId;

    /**
     * 昵称。
     */
    @Schema(description = "昵称")
    private String nickname;

    /**
     * 访问令牌（短效），后续请求通过 Authorization 请求头携带。
     */
    @Schema(description = "访问令牌")
    private String accessToken;

    /**
     * 刷新令牌（长效），access token 过期后调刷新接口换取新令牌对。
     */
    @Schema(description = "刷新令牌")
    private String refreshToken;
}
