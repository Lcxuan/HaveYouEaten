package com.hye.framework.amap.service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 高德 POI 详情的 HTTP query 参数。
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmapDetailQueryDTO {

    /**
     * 高德 POI id。
     */
    private String id;

    /**
     * 需要返回的扩展字段。
     */
    private String showFields;

    /**
     * 高德开发者 key。
     */
    private String key;
}