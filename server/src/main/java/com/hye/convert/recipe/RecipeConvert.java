package com.hye.convert.recipe;

import com.hye.controller.recipe.vo.RecipeDetailVO;
import com.hye.controller.recipe.vo.RecipeSummaryVO;
import com.hye.entity.RecipeDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

/**
 * 菜谱对象转换器。
 */
@Mapper
public interface RecipeConvert {

    RecipeConvert INSTANCE = Mappers.getMapper(RecipeConvert.class);

    /**
     * 菜谱实体转摘要 VO。
     *
     * @param recipe 菜谱实体
     * @return 摘要 VO
     */
    RecipeSummaryVO toSummary(RecipeDO recipe);

    /**
     * 菜谱实体转详情 VO。
     *
     * @param recipe 菜谱实体
     * @return 详情 VO
     */
    RecipeDetailVO toDetail(RecipeDO recipe);
}
