package com.hye.controller.restaurant.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@Schema(description = "本次抽中的菜系")
public class RestaurantCuisineVO {

    @Schema(description = "菜系 id")
    private Long id;

    @Schema(description = "菜系名")
    private String name;
}
