package com.hye.controller.restaurant.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "出去吃菜系字典项")
public class DineCuisineVO {

    @Schema(description = "菜系 id")
    private Long id;

    @Schema(description = "菜系名称")
    private String name;

    @Schema(description = "排序值，越小越靠前")
    private Integer sort;
}