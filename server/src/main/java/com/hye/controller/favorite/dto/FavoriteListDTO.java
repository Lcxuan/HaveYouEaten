package com.hye.controller.favorite.dto;

import com.hye.common.pojo.PageParam;
import com.hye.enums.favorite.FavoriteTargetTypeEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "收藏列表查询参数")
public class FavoriteListDTO extends PageParam {

    @Schema(description = "类型：recipe-菜谱，restaurant-餐厅")
    @NotBlank(message = "收藏类型不能为空")
    @Pattern(regexp = FavoriteTargetTypeEnum.CODES_REGEXP,
            message = "收藏类型仅支持 recipe 或 restaurant")
    private String targetType;
}
