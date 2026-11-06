package com.hye.controller.recipe.vo;

import com.hye.entity.RecipeIngredientDO;
import com.hye.entity.RecipeStepDO;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * 菜谱详情：含完整食材清单与做法步骤。
 */
@Data
@Schema(description = "菜谱详情")
public class RecipeDetailVO {

    @Schema(description = "菜谱 id")
    private Long id;

    @Schema(description = "菜名")
    private String name;

    @Schema(description = "简介")
    private String description;

    @Schema(description = "菜系")
    private String cuisine;

    @Schema(description = "难度：1-简单，2-中等，3-困难")
    private Integer difficulty;

    @Schema(description = "烹饪时长（分钟）")
    private Integer cookMinutes;

    @Schema(description = "口味标签")
    private List<String> tags;

    @Schema(description = "食材清单")
    private List<RecipeIngredientDO> ingredients;

    @Schema(description = "做法步骤")
    private List<RecipeStepDO> steps;

    @Schema(description = "AI 生成/改写的字段名数组，取值：description / ingredients / steps / image_url")
    private List<String> aigcFields;

    @Schema(description = "封面图地址")
    private String imageUrl;

    @Schema(description = "来源：ai-AI 生成，import-开源菜谱导入，manual-人工录入")
    private String source;
}
