package com.hye.controller.restaurant.dto;

import com.hye.enums.restaurant.RestaurantSearchRadiusEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
@Schema(description = "出去吃发牌参数")
public class RestaurantDeckDTO {

    @NotNull(message = "经度不能为空")
    @DecimalMin(value = "-180", message = "经度不能小于 -180")
    @DecimalMax(value = "180", message = "经度不能大于 180")
    @Schema(description = "经度（GCJ-02）")
    private Double lng;

    @NotNull(message = "纬度不能为空")
    @DecimalMin(value = "-90", message = "纬度不能小于 -90")
    @DecimalMax(value = "90", message = "纬度不能大于 90")
    @Schema(description = "纬度（GCJ-02）")
    private Double lat;

    @Min(value = 500, message = "搜索半径不能小于 500 米")
    @Max(value = 5000, message = "搜索半径不能大于 5000 米")
    @Schema(description = "搜索半径（米），默认 3000，范围 500-5000")
    private Integer radius = RestaurantSearchRadiusEnum.DEFAULT.getValue();

    @Schema(description = "抽签池菜系 id，空表示当前餐段全部菜系")
    private List<Long> cuisineIds;

    @Schema(description = "排除的菜系 id，「换菜系」时带上刚抽过的")
    private List<Long> excludeCuisineIds;

    @Schema(description = "人均预算上限（元），空表示不限")
    private Integer maxCost;
}
