package com.hye.mapper;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.hye.entity.UserDO;

/**
 * 用户 Mapper。
 */
public interface UserMapper extends BaseMapper<UserDO> {

    /**
     * 按手机号统计数量，用于注册时查重。
     *
     * @param phone 手机号
     * @return 数量
     */
    default Long countByPhone(String phone) {
        return selectCount(byPhoneQuery(phone));
    }

    /**
     * 按手机号查询用户，用于登录。
     *
     * @param phone 手机号
     * @return 用户，未匹配返回 null
     */
    default UserDO selectByPhone(String phone) {
        return selectOne(byPhoneQuery(phone));
    }

    /**
     * 构建按手机号匹配的查询条件。
     */
    private static LambdaQueryWrapper<UserDO> byPhoneQuery(String phone) {
        return Wrappers.<UserDO>lambdaQuery().eq(UserDO::getPhone, phone);
    }
}
