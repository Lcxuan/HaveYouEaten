package com.hye.mapper;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.hye.common.mapper.BaseMapperPlus;
import com.hye.common.pojo.PageParam;
import com.hye.common.pojo.PageResult;
import com.hye.entity.FavoriteDO;

public interface FavoriteMapper extends BaseMapperPlus<FavoriteDO> {

    /**
     * 查询用户对某个目标的收藏记录。
     *
     * @param userId     用户 id
     * @param targetType 类型：recipe / restaurant
     * @param targetId   目标 id
     * @return 不存在时返回 null
     */
    default FavoriteDO selectByTarget(Long userId, String targetType, String targetId) {
        return selectOne(Wrappers.<FavoriteDO>lambdaQuery()
                .eq(FavoriteDO::getUserId, userId)
                .eq(FavoriteDO::getTargetType, targetType)
                .eq(FavoriteDO::getTargetId, targetId));
    }

    /**
     * 分页查询用户某一类型的收藏，按收藏时间倒序。
     *
     * @param userId     用户 id
     * @param targetType 类型：recipe / restaurant
     * @param pageParam  分页参数
     * @return 分页收藏
     */
    default PageResult<FavoriteDO> selectPageByType(Long userId, String targetType, PageParam pageParam) {
        return selectPage(pageParam, Wrappers.<FavoriteDO>lambdaQuery()
                .eq(FavoriteDO::getUserId, userId)
                .eq(FavoriteDO::getTargetType, targetType)
                .orderByDesc(FavoriteDO::getCreateTime)
                .orderByDesc(FavoriteDO::getId));
    }

    /**
     * 取消收藏。
     *
     * @param userId     用户 id
     * @param targetType 类型：recipe / restaurant
     * @param targetId   目标 id
     * @return 影响行数
     */
    default int deleteByTarget(Long userId, String targetType, String targetId) {
        return delete(Wrappers.<FavoriteDO>lambdaQuery()
                .eq(FavoriteDO::getUserId, userId)
                .eq(FavoriteDO::getTargetType, targetType)
                .eq(FavoriteDO::getTargetId, targetId));
    }
}
