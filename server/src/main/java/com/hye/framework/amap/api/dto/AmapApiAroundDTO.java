package com.hye.framework.amap.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmapApiAroundDTO {

    /**
     * 高德分类码，多个用 | 分隔，为空时回退餐饮大类。
     */
    private String types;

    /**
     * 菜系名，作为 keywords 参数，可为空。
     */
    private String keywords;

    /**
     * 经度（GCJ-02）。
     */
    private double lng;

    /**
     * 纬度（GCJ-02）。
     */
    private double lat;

    /**
     * 半径（米）。
     */
    private int radius;

    /**
     * 页码，从 1 开始。
     */
    private int pageNum;
}