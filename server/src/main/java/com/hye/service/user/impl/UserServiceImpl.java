package com.hye.service.user.impl;

import cn.dev33.satoken.stp.StpUtil;
import cn.hutool.core.util.IdUtil;
import cn.hutool.crypto.digest.BCrypt;
import com.hye.common.enums.CommonStatusEnum;
import com.hye.config.RefreshTokenProperties;
import com.hye.controller.user.dto.UserLoginDTO;
import com.hye.controller.user.dto.UserRefreshDTO;
import com.hye.controller.user.dto.UserRegisterDTO;
import com.hye.controller.user.vo.UserLoginVO;
import com.hye.convert.user.UserConvert;
import com.hye.entity.UserDO;
import com.hye.enums.exception.BusinessErrorCodeConstants;
import com.hye.enums.exception.BusinessException;
import com.hye.mapper.UserMapper;
import com.hye.redis.auth.AuthRedisKey;
import com.hye.service.user.UserService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

/**
 * 用户业务实现：注册、登录与令牌刷新。
 */
@Slf4j
@Service
public class UserServiceImpl implements UserService {

    @Resource
    private UserMapper userMapper;

    @Resource
    private RefreshTokenProperties refreshTokenProperties;

    @Resource
    private AuthRedisKey authRedisKey;

    @Override
    public Long register(UserRegisterDTO dto) {
        if (userMapper.countByPhone(dto.getPhone()) > 0) {
            throw new BusinessException(BusinessErrorCodeConstants.USER_PHONE_REGISTERED);
        }
        UserDO user = UserConvert.INSTANCE.convert(dto);
        user.setPassword(BCrypt.hashpw(dto.getPassword()));
        // 昵称不填时，默认用“用户 + 手机号后四位”
        user.setNickname(StringUtils.hasText(user.getNickname()) ? user.getNickname() : "用户" + dto.getPhone().substring(7));
        user.setStatus(CommonStatusEnum.ENABLE.getCode());
        userMapper.insert(user);
        return user.getId();
    }

    @Override
    public UserLoginVO login(UserLoginDTO dto) {
        UserDO user = userMapper.selectByPhone(dto.getPhone());
        if (user == null || !BCrypt.checkpw(dto.getPassword(), user.getPassword())) {
            throw new BusinessException(BusinessErrorCodeConstants.LOGIN_FAILED);
        }
        if (!CommonStatusEnum.isEnabled(user.getStatus())) {
            throw new BusinessException(BusinessErrorCodeConstants.USER_DISABLED);
        }
        // 记录最后登录时间
        user.setLastLoginTime(LocalDateTime.now());
        userMapper.updateById(user);
        return issueTokens(user);
    }

    @Override
    public UserLoginVO refresh(UserRefreshDTO dto) {
        String userId = authRedisKey.getRefreshTokenUserId(dto.getRefreshToken());
        if (!StringUtils.hasText(userId)) {
            throw new BusinessException(BusinessErrorCodeConstants.REFRESH_TOKEN_INVALID);
        }
        // 轮换：作废旧 refresh token，防止重复使用
        authRedisKey.deleteRefreshToken(dto.getRefreshToken());
        UserDO user = userMapper.selectById(Long.valueOf(userId));
        if (user == null) {
            throw new BusinessException(BusinessErrorCodeConstants.USER_NOT_FOUND);
        }
        if (!CommonStatusEnum.isEnabled(user.getStatus())) {
            throw new BusinessException(BusinessErrorCodeConstants.USER_DISABLED);
        }
        return issueTokens(user);
    }

    /**
     * 签发令牌对：Sa-Token 会话作为短效 access token，自生成 refresh token 存 Redis。
     */
    private UserLoginVO issueTokens(UserDO user) {
        StpUtil.login(user.getId());
        String refreshToken = IdUtil.fastSimpleUUID();
        authRedisKey.setRefreshToken(refreshToken, user.getId(), refreshTokenProperties.getRefreshTimeoutDuration());
        return UserLoginVO.builder()
                .userId(user.getId())
                .nickname(user.getNickname())
                .accessToken(StpUtil.getTokenValue())
                .refreshToken(refreshToken)
                .build();
    }
}
