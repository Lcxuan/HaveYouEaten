package com.hye.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.hye.common.entity.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 用户实体。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("users")
public class UserDO extends BaseDO {

    /**
     * 密码（BCrypt 加密存储）。
     */
    private String password;

    /**
     * 昵称（展示用）。
     */
    private String nickname;

    /**
     * 手机号（可作为登录标识，唯一）。
     */
    private String phone;

    /**
     * 状态：0-禁用，1-正常。
     */
    private Integer status;

    /**
     * 最后登录时间。
     */
    private LocalDateTime lastLoginTime;
}
