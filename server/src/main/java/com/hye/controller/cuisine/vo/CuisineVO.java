package com.hye.controller.cuisine.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * 菜系字典项。
 */
@Data
@Schema(description = "菜系字典项")
public class CuisineVO {

    @Schema(description = "菜系 id")
    private Long id;

    @Schema(description = "菜系名称")
    private String name;

    @Schema(description = "适用餐段：1-早餐，2-午餐，3-晚餐，4-夜宵（可多选）")
    private List<Integer> mealPeriods;

    @Schema(description = "排序值，越小越靠前")
    private Integer sort;
}
