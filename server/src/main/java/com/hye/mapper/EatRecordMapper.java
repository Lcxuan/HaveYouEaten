package com.hye.mapper;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.hye.common.mapper.BaseMapperPlus;
import com.hye.common.pojo.PageParam;
import com.hye.common.pojo.PageResult;
import com.hye.entity.EatRecordDO;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 吃过记录 Mapper。
 */
public interface EatRecordMapper extends BaseMapperPlus<EatRecordDO> {

    /**
     * 分页查询用户某时间之后的吃饭记录，按吃饭时间倒序，id 兜底保证顺序稳定。
     *
     * @param userId    用户 id
     * @param since     起始时间（含）
     * @param pageParam 分页参数
     * @return 分页结果
     */
    default PageResult<EatRecordDO> selectRecentPage(Long userId, LocalDateTime since, PageParam pageParam) {
        return selectPage(pageParam, Wrappers.<EatRecordDO>lambdaQuery()
                .eq(EatRecordDO::getUserId, userId)
                .ge(EatRecordDO::getEatenAt, since)
                .orderByDesc(EatRecordDO::getEatenAt)
                .orderByDesc(EatRecordDO::getId));
    }

    /**
     * 查询用户某时间之后吃过（在家吃）的记录，仅取菜谱 id 字段，用于抽签去重。
     *
     * @param userId 用户 id
     * @param since  起始时间（含）
     * @return 记录列表（recipeId 非空）
     */
    default List<EatRecordDO> selectRecentRecipeRecords(Long userId, LocalDateTime since) {
        return selectList(Wrappers.<EatRecordDO>lambdaQuery()
                .select(EatRecordDO::getRecipeId)
                .eq(EatRecordDO::getUserId, userId)
                .ge(EatRecordDO::getEatenAt, since)
                .isNotNull(EatRecordDO::getRecipeId));
    }
}
