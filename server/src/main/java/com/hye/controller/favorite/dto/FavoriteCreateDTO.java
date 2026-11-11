package com.hye.controller.favorite.dto;

import com.hye.enums.favorite.FavoriteTargetTypeEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

import java.util.Map;

@Data
@Schema(description = "新增收藏参数")
public class FavoriteCreateDTO {

    @Schema(description = "类型：recipe-菜谱，restaurant-餐厅")
    @NotBlank(message = "收藏类型不能为空")
    @Pattern(regexp = FavoriteTargetTypeEnum.CODES_REGEXP,
            message = "收藏类型仅支持 recipe 或 restaurant")
    private String targetType;

    @Schema(description = "目标 id（菜谱 id 或高德 POI id）")
    @NotBlank(message = "收藏目标不能为空")
    private String targetId;

    @Schema(description = "名称冗余（菜名/店名）")
    @NotBlank(message = "收藏名称不能为空")
    private String name;

    @Schema(description = "餐厅快照（仅餐厅收藏使用，保存展示信息，避免后续再查高德）")
    private Map<String, Object> extra;
}
