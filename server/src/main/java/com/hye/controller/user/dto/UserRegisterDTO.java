package com.hye.controller.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 注册请求参数。
 */
@Data
@Schema(description = "注册请求")
public class UserRegisterDTO {

    /**
     * 手机号，可作为登录标识。
     */
    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^1\\d{10}$", message = "手机号格式不正确")
    @Schema(description = "手机号")
    private String phone;

    /**
     * 昵称。
     */
    @Size(max = 32, message = "昵称最长 32 位")
    @Schema(description = "昵称，不填默认同用户名")
    private String nickname;

    /**
     * 登录密码。
     */
    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 32, message = "密码长度 6-32 位")
    @Schema(description = "登录密码")
    private String password;
}
