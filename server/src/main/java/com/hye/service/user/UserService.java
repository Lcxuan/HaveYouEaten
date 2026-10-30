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
     * 注册
     *
     * @param dto 注册参数
     * @return 用户 id
     */
    Long register(UserRegisterDTO dto);

    /**
     * 登录
     *
     * @param dto 登录参数
     * @return 用户信息与令牌对
     */
    UserLoginVO login(UserLoginDTO dto);

    /**
     * 刷新令牌
     *
     * @param dto 刷新参数
     * @return 新的令牌对
     */
    UserLoginVO refresh(UserRefreshDTO dto);

    /**
     * 退出登录
     */
    void logout();
}
