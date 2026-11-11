package com.hye.controller.favorite.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@Schema(description = "收藏记录")
public class FavoriteVO {

    @Schema(description = "收藏 id")
    private Long id;

    @Schema(description = "类型：recipe-菜谱，restaurant-餐厅")
    private String targetType;

    @Schema(description = "目标 id（菜谱 id 或高德 POI id）")
    private String targetId;

    @Schema(description = "名称（菜名/店名）")
    private String name;

    @Schema(description = "餐厅快照（仅餐厅收藏有值）")
    private Map<String, Object> extra;

    @Schema(description = "收藏时间")
    private LocalDateTime createTime;
}
