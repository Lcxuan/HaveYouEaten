package com.hye.controller.recipe.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * 菜谱摘要
 */
@Data
@Schema(description = "菜谱摘要")
public class RecipeSummaryVO {

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

    @Schema(description = "封面图地址")
    private String imageUrl;

    @Schema(description = "来源：ai-AI 生成，import-开源菜谱导入，manual-人工录入")
    private String source;
}
