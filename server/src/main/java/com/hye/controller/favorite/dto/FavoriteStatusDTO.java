package com.hye.controller.favorite.dto;

import com.hye.enums.favorite.FavoriteTargetTypeEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
@Schema(description = "收藏状态查询参数")
public class FavoriteStatusDTO {

    @Schema(description = "类型：recipe-菜谱，restaurant-餐厅")
    @NotBlank(message = "收藏类型不能为空")
    @Pattern(regexp = FavoriteTargetTypeEnum.CODES_REGEXP,
            message = "收藏类型仅支持 recipe 或 restaurant")
    private String targetType;

    @Schema(description = "目标 id（菜谱 id 或高德 POI id）")
    @NotBlank(message = "收藏目标不能为空")
    private String targetId;
}
