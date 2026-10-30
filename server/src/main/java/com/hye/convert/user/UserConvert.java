package com.hye.convert.user;

import com.hye.controller.user.dto.UserRegisterDTO;
import com.hye.entity.UserDO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

/**
 * 用户对象转换器。
 */
@Mapper
public interface UserConvert {

    UserConvert INSTANCE = Mappers.getMapper(UserConvert.class);

    /**
     * 注册参数转用户实体，密码不参与自动映射（需 BCrypt 加密后单独赋值）。
     *
     * @param dto 注册参数
     * @return 用户实体
     */
    @Mapping(target = "password", ignore = true)
    UserDO convert(UserRegisterDTO dto);
}
