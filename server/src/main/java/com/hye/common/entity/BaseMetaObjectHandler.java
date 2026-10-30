package com.hye.common.entity;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import com.hye.common.utils.LoginContextHolder;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 数据库公共字段自动填充处理器。
 */
@Component
public class BaseMetaObjectHandler implements MetaObjectHandler {

    /**
     * 新增记录时填充创建/更新时间与创建/更新人。
     */
    @Override
    public void insertFill(MetaObject metaObject) {
        LocalDateTime now = LocalDateTime.now();
        strictInsertFill(metaObject, "createTime", LocalDateTime.class, now);
        strictInsertFill(metaObject, "updateTime", LocalDateTime.class, now);
        Long userId = LoginContextHolder.getUserId();
        strictInsertFill(metaObject, "createBy", Long.class, userId);
        strictInsertFill(metaObject, "updateBy", Long.class, userId);
    }

    /**
     * 更新记录时填充更新时间与更新人。
     */
    @Override
    public void updateFill(MetaObject metaObject) {
        strictUpdateFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
        strictUpdateFill(metaObject, "updateBy", Long.class, LoginContextHolder.getUserId());
    }
}
