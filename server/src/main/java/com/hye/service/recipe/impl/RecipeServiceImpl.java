package com.hye.service.recipe.impl;

import com.hye.common.enums.CommonStatusEnum;
import com.hye.common.utils.CollectionUtil;
import com.hye.common.utils.DateUtils;
import com.hye.common.utils.LoginContextHolder;
import com.hye.controller.cuisine.vo.CuisineVO;
import com.hye.controller.recipe.dto.RecipeDrawDTO;
import com.hye.controller.recipe.vo.RecipeDetailVO;
import com.hye.controller.recipe.vo.RecipeDrawVO;
import com.hye.controller.recipe.vo.RecipeSummaryVO;
import com.hye.convert.recipe.RecipeConvert;
import com.hye.entity.EatRecordDO;
import com.hye.entity.RecipeDO;
import com.hye.enums.blacklist.BlacklistScopeEnum;
import com.hye.enums.exception.BusinessErrorCodeConstants;
import com.hye.common.enums.exception.BusinessException;
import com.hye.enums.recipe.RecipeDrawRuleEnum;
import com.hye.mapper.EatRecordMapper;
import com.hye.mapper.RecipeMapper;
import com.hye.service.blacklist.BlacklistService;
import com.hye.service.cuisine.CuisineService;
import com.hye.service.recipe.RecipeService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 菜谱业务实现：抽签与详情。
 */
@Service
public class RecipeServiceImpl implements RecipeService {

    @Resource
    private RecipeMapper recipeMapper;

    @Resource
    private EatRecordMapper eatRecordMapper;

    @Resource
    private CuisineService cuisineService;

    @Resource
    private BlacklistService blacklistService;

    @Override
    public RecipeDrawVO draw(RecipeDrawDTO dto) {
        List<RecipeDO> pool = filter(recipeMapper.selectEnabled(), dto);
        // 获取用户最近 N 天（具体天数根据 RecipeDrawRuleEnum.RECENT_DAYS）吃过的菜谱 id 列表
        List<EatRecordDO> recentRecords = eatRecordMapper.selectRecentRecipeRecords(
                LoginContextHolder.getUserId(),
                DateUtils.nowMinusDays(RecipeDrawRuleEnum.RECENT_DAYS.getDays()));
        Set<Long> recentIds = CollectionUtil.convertSet(recentRecords, EatRecordDO::getRecipeId);
        // 过滤掉最近 N 天（具体天数根据 RecipeDrawRuleEnum.RECENT_DAYS）吃过的菜谱
        pool = CollectionUtil.filterList(pool, r -> !recentIds.contains(r.getId()));
        if (pool.isEmpty()) {
            throw new BusinessException(BusinessErrorCodeConstants.RECIPE_POOL_EMPTY);
        }
        // 过滤黑名单：菜谱按 id，菜系按名称映射成 id
        pool = filterBlacklist(pool, LoginContextHolder.getUserId());
        if (pool.isEmpty()) {
            throw new BusinessException(BusinessErrorCodeConstants.RECIPE_POOL_BLACKLIST_EMPTY);
        }
        // 从候选池中随机抽取一道菜品
        RecipeDO winner = pool.get(ThreadLocalRandom.current().nextInt(pool.size()));
        RecipeSummaryVO summary = RecipeConvert.INSTANCE.toSummary(winner);
        summary.setCuisine(cuisineService.getCuisineName(winner.getCuisineId()));
        return RecipeDrawVO.builder()
                .poolSize(pool.size())
                .recipe(summary)
                .build();
    }

    @Override
    public RecipeDetailVO getDetail(Long id) {
        RecipeDO recipe = recipeMapper.selectById(id);
        if (recipe == null || !CommonStatusEnum.isEnabled(recipe.getEnabled())) {
            throw new BusinessException(BusinessErrorCodeConstants.RECIPE_NOT_FOUND);
        }
        RecipeDetailVO detail = RecipeConvert.INSTANCE.toDetail(recipe);
        detail.setCuisine(cuisineService.getCuisineName(recipe.getCuisineId()));
        return detail;
    }

    /**
     * 过滤黑名单：菜谱维度按 id 排除，菜系维度把菜系名映射成 id 后排除。
     */
    private List<RecipeDO> filterBlacklist(List<RecipeDO> pool, Long userId) {
        Set<String> blockedRecipes = blacklistService.getBlockedValues(
                userId, BlacklistScopeEnum.RECIPE.getCode());
        Set<String> blockedCuisines = blacklistService.getBlockedValues(
                userId, BlacklistScopeEnum.CUISINE.getCode());
        if (blockedRecipes.isEmpty() && blockedCuisines.isEmpty()) {
            return pool;
        }
        Set<Long> blockedCuisineIds = new HashSet<>();
        if (!blockedCuisines.isEmpty()) {
            for (CuisineVO cuisine : cuisineService.getEnabledList()) {
                if (blockedCuisines.contains(cuisine.getName())) {
                    blockedCuisineIds.add(cuisine.getId());
                }
            }
        }
        return CollectionUtil.filterList(pool, recipe ->
                !blockedRecipes.contains(String.valueOf(recipe.getId()))
                        && !blockedCuisineIds.contains(recipe.getCuisineId()));
    }

    /**
     * 按筛选条件过滤候选池：菜系多选任一命中、口味任一命中、时长上限、难度精确匹配。
     */
    private List<RecipeDO> filter(List<RecipeDO> pool, RecipeDrawDTO dto) {
        return pool.stream()
                // 菜系：多选，菜谱关联的任一菜系命中即可；未选视为不限
                .filter(r -> matchCuisines(r, dto.getCuisineIds()))
                // 口味：与菜谱标签存在交集即命中；未选视为不限
                .filter(r -> matchTastes(r, dto.getTastes()))
                // 时长上限：菜谱时长不超过上限；菜谱时长缺失时不参与命中
                .filter(r -> dto.getMaxCookMinutes() == null
                        || r.getCookMinutes() != null && r.getCookMinutes() <= dto.getMaxCookMinutes())
                // 难度：精确匹配；未选视为不限
                .filter(r -> dto.getDifficulty() == null || dto.getDifficulty().equals(r.getDifficulty()))
                .toList();
    }

    /**
     * 菜系匹配：菜谱的菜系 id 在所选菜系中即命中；未选视为不限。
     */
    private boolean matchCuisines(RecipeDO recipe, List<Long> cuisineIds) {
        if (CollectionUtils.isEmpty(cuisineIds)) {
            return true;
        }
        return recipe.getCuisineId() != null && cuisineIds.contains(recipe.getCuisineId());
    }

    /**
     * 口味匹配：候选菜谱标签与所选口味存在任一交集即命中；未选口味视为不限。
     */
    private boolean matchTastes(RecipeDO recipe, List<String> tastes) {
        if (CollectionUtils.isEmpty(tastes)) {
            return true;
        }
        List<String> tags = recipe.getTags() == null ? List.of() : recipe.getTags();
        return tastes.stream().anyMatch(tags::contains);
    }
}
