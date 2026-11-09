package com.hye.framework.amap.service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmapAroundQueryDTO {

    /**
     * 查询中心点坐标，格式 lng,lat（GCJ-02）。
     */
    private String location;

    /**
     * 搜索半径（米）。
     */
    private String radius;

    /**
     * 高德分类码，多个用 | 分隔。
     */
    private String types;

    /**
     * 关键词。
     */
    private String keywords;

    /**
     * 排序规则，如 distance 按距离排序。
     */
    private String sortrule;

    /**
     * 每页条数。
     */
    private String pageSize;

    /**
     * 页码，从 1 开始。
     */
    private String pageNum;

    /**
     * 需要返回的扩展字段。
     */
    private String showFields;

    /**
     * 高德开发者 key。
     */
    private String key;
}