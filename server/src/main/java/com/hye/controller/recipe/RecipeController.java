package com.hye.controller.recipe;

import com.hye.common.Result;
import com.hye.controller.recipe.dto.RecipeDrawDTO;
import com.hye.controller.recipe.vo.RecipeDetailVO;
import com.hye.controller.recipe.vo.RecipeDrawVO;
import com.hye.service.recipe.RecipeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 菜谱接口：抽签与详情。
 */
@Tag(name = "菜谱")
@RestController
@RequestMapping("/api/recipe")
public class RecipeController {

    @Resource
    private RecipeService recipeService;

    /**
     * 抽签：按筛选条件随机抽一道菜，筛选条件全部可空（全池随机）。
     *
     * @param dto 筛选条件，全部可空
     * @return 抽中菜谱与候选池大小
     */
    @PostMapping("/draw")
    @Operation(summary = "转盘抽签")
    public Result<RecipeDrawVO> draw(@RequestBody RecipeDrawDTO dto) {
        return Result.success(recipeService.draw(dto));
    }

    /**
     * 菜谱详情。
     *
     * @param id 菜谱 id
     * @return 详情
     */
    @GetMapping("/{id}")
    @Operation(summary = "菜谱详情")
    public Result<RecipeDetailVO> detail(@PathVariable Long id) {
        return Result.success(recipeService.getDetail(id));
    }
}
