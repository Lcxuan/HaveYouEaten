package com.hye.service.recipe;

import com.hye.controller.recipe.dto.RecipeDrawDTO;
import com.hye.controller.recipe.vo.RecipeDetailVO;
import com.hye.controller.recipe.vo.RecipeDrawVO;

/**
 * 菜谱业务接口。
 */
public interface RecipeService {

    /**
     * 抽签：按筛选条件过滤候选池（排除当前用户最近 7 天吃过的）后随机抽取。
     *
     * @param dto 筛选条件，全部可空
     * @return 抽中菜谱与候选池大小
     */
    RecipeDrawVO draw(RecipeDrawDTO dto);

    /**
     * 菜谱详情。
     *
     * @param id 菜谱 id
     * @return 详情
     */
    RecipeDetailVO getDetail(Long id);
}
