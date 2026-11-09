package com.hye.controller.restaurant.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@Schema(description = "出去吃发牌结果")
public class RestaurantDeckVO {

    @Schema(description = "本次抽中的菜系")
    private RestaurantCuisineVO cuisine;

    @Schema(description = "过滤后的候选店数")
    private Integer poolSize;

    @Schema(description = "按翻牌顺序排列的卡片")
    private List<RestaurantVO> options;
}
