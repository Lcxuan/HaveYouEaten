package com.hye.controller.auth;

import com.hye.common.Result;
import com.hye.common.annotation.HeaderBind;
import com.hye.controller.auth.dto.AuthHandshakeDTO;
import com.hye.controller.auth.vo.AuthHandshakeVO;
import com.hye.service.auth.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 认证接口：App 启动时用预置 APP_KEY 换取短期 access token。
 */
@Tag(name = "认证")
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Resource
    private AuthService authService;

    @PostMapping("/handshake")
    @Operation(summary = "获取短期访问token", description = "App 启动时以预置 APP_KEY 换取短期 access token")
    public Result<AuthHandshakeVO> handshake(@HeaderBind @Parameter(hidden = true) AuthHandshakeDTO dto) {
        return Result.success(authService.handshake(dto));
    }
}
