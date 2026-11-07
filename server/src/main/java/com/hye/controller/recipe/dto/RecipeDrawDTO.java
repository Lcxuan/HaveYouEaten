package com.hye.controller.recipe.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Data
@Schema(description = "抽签参数")
public class RecipeDrawDTO {

    @Schema(description = "菜系 id 列表（多选，命中任一即可，空为不限）", example = "[1, 2]")
    private List<Long> cuisineIds;

    @Schema(description = "口味标签（多选，命中任一即可，空为不限）", example = "[\"微辣\", \"下饭\"]")
    private List<String> tastes;

    @Schema(description = "烹饪时长上限（分钟）", example = "45")
    private Integer maxCookMinutes;

    @Schema(description = "难度：1-简单，2-中等，3-困难", example = "2")
    private Integer difficulty;
}
