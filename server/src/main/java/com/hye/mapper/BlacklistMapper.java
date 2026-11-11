package com.hye.mapper;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.hye.common.mapper.BaseMapperPlus;
import com.hye.entity.BlacklistDO;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

public interface BlacklistMapper extends BaseMapperPlus<BlacklistDO> {

    /**
     * 查询用户对某个值的黑名单记录。
     *
     * @param userId      用户 id
     * @param scope       粒度：cuisine / poi / recipe
     * @param targetValue 屏蔽值
     * @return 黑名单记录；不存在时返回 null
     */
    default BlacklistDO selectByTarget(Long userId, String scope, String targetValue) {
        return selectOne(Wrappers.<BlacklistDO>lambdaQuery()
                .eq(BlacklistDO::getUserId, userId)
                .eq(BlacklistDO::getScope, scope)
                .eq(BlacklistDO::getTargetValue, targetValue));
    }

    /**
     * 查询用户某个粒度下的全部屏蔽值，供抽签过滤使用。
     *
     * @param userId 用户 id
     * @param scope  粒度：cuisine / poi / recipe
     * @return 屏蔽值列表
     */
    @Select("SELECT target_value FROM blacklist "
            + "WHERE user_id = #{userId} AND scope = #{scope} AND deleted = 0")
    List<String> selectTargetValues(@Param("userId") Long userId, @Param("scope") String scope);

    /**
     * 查询用户某个粒度下的黑名单记录。
     *
     * @param userId 用户 id
     * @param scope  粒度：cuisine / poi / recipe
     * @return 黑名单记录，按创建时间倒序
     */
    default List<BlacklistDO> selectListByScope(Long userId, String scope) {
        return selectList(Wrappers.<BlacklistDO>lambdaQuery()
                .eq(BlacklistDO::getUserId, userId)
                .eq(BlacklistDO::getScope, scope)
                .orderByDesc(BlacklistDO::getCreateTime)
                .orderByDesc(BlacklistDO::getId));
    }

    /**
     * 物理删除黑名单，保证移除后可以重新拉黑。
     *
     * @param userId      用户 id
     * @param scope       粒度：cuisine / poi / recipe
     * @param targetValue 屏蔽值
     * @return 影响行数
     */
    @Delete("DELETE FROM blacklist WHERE user_id = #{userId} "
            + "AND scope = #{scope} AND target_value = #{targetValue}")
    int deleteByTarget(@Param("userId") Long userId,
                       @Param("scope") String scope,
                       @Param("targetValue") String targetValue);
}
