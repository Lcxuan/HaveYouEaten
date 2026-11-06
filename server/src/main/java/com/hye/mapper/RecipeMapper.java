package com.hye.mapper;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.hye.common.enums.CommonStatusEnum;
import com.hye.common.mapper.BaseMapperPlus;
import com.hye.entity.RecipeDO;

import java.util.List;

/**
 * 菜谱 Mapper。
 */
public interface RecipeMapper extends BaseMapperPlus<RecipeDO> {

    /**
     * 查询全部上架菜谱
     *
     * @return 上架菜谱列表
     */
    default List<RecipeDO> selectEnabled() {
        return selectList(Wrappers.<RecipeDO>lambdaQuery().eq(RecipeDO::getEnabled, CommonStatusEnum.ENABLE.getCode()));
    }
}
