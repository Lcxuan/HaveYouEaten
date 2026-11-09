package com.hye.controller.restaurant.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Data
@Schema(description = "餐厅卡片")
public class RestaurantVO {

    @Schema(description = "高德 POI id")
    private String poiId;

    @Schema(description = "店名")
    private String name;

    @Schema(description = "地址")
    private String address;

    @Schema(description = "距你距离（米）")
    private Integer distance;

    @Schema(description = "人均（元），可能为空")
    private Double cost;

    @Schema(description = "评分，可能为空")
    private Double rating;

    @Schema(description = "高德分类码")
    private String typecode;

    @Schema(description = "标签")
    private List<String> tags;

    @Schema(description = "经度")
    private Double lng;

    @Schema(description = "纬度")
    private Double lat;

    @Schema(description = "电话")
    private String tel;

    @Schema(description = "今日营业时间")
    private String openTime;

    @Schema(description = "入口坐标 lng,lat")
    private String entrLocation;

    @Schema(description = "封面图")
    private String photo;
}
