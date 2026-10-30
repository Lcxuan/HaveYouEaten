package com.hye.service.user;

import com.hye.controller.user.dto.UserLoginDTO;
import com.hye.controller.user.dto.UserRefreshDTO;
import com.hye.controller.user.dto.UserRegisterDTO;
import com.hye.controller.user.vo.UserLoginVO;

/**
 * 用户业务接口。
 */
public interface UserService {

    /**
     * 注册：校验用户名与手机号唯一后创建账号。
     *
     * @param dto 注册参数
     * @return 用户 id
     */
    Long register(UserRegisterDTO dto);

    /**
     * 登录：校验账号密码，签发 access token 与 refresh token。
     *
     * @param dto 登录参数
     * @return 用户信息与令牌对
     */
    UserLoginVO login(UserLoginDTO dto);

    /**
     * 刷新令牌：校验 refresh token，轮换签发新的令牌对。
     *
     * @param dto 刷新参数
     * @return 新的令牌对
     */
    UserLoginVO refresh(UserRefreshDTO dto);
}
