package com.hye.controller.user;

import com.hye.common.Result;
import com.hye.controller.user.dto.UserLoginDTO;
import com.hye.controller.user.dto.UserRefreshDTO;
import com.hye.controller.user.dto.UserRegisterDTO;
import com.hye.controller.user.vo.UserLoginVO;
import com.hye.service.user.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户接口：注册与登录。
 */
@Tag(name = "用户")
@RestController
@RequestMapping("/api/user")
public class UserController {

    @Resource
    private UserService userService;

    /**
     * 注册账号。
     *
     * @param dto 注册参数
     * @return 用户 id
     */
    @PostMapping("/register")
    @Operation(summary = "注册账号")
    public Result<Long> register(@Valid @RequestBody UserRegisterDTO dto) {
        return Result.success(userService.register(dto));
    }

    /**
     * 登录，返回用户信息与 Sa-Token 令牌。
     *
     * @param dto 登录参数
     * @return 用户信息与令牌
     */
    @PostMapping("/login")
    @Operation(summary = "登录")
    public Result<UserLoginVO> login(@Valid @RequestBody UserLoginDTO dto) {
        return Result.success(userService.login(dto));
    }

    /**
     * 刷新令牌：用 refresh token 换取新的令牌对。
     *
     * @param dto 刷新参数
     * @return 新的令牌对
     */
    @PostMapping("/refresh")
    @Operation(summary = "刷新令牌")
    public Result<UserLoginVO> refresh(@Valid @RequestBody UserRefreshDTO dto) {
        return Result.success(userService.refresh(dto));
    }
}
