package com.hye.controller.recipe.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@Schema(description = "抽签结果")
public class RecipeDrawVO {

    @Schema(description = "本次候选池大小（已按筛选条件与近期吃过排除）")
    private Integer poolSize;

    @Schema(description = "抽中的菜谱")
    private RecipeSummaryVO recipe;
}
