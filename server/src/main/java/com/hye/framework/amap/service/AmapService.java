package com.hye.framework.amap.service;

import com.hye.framework.amap.api.dto.AmapApiAroundDTO;
import com.hye.framework.amap.api.vo.AmapApiPoiVO;

import java.util.List;

public interface AmapService {

    /**
     * 按分类码与关键词搜索周边餐饮。
     *
     * @param dto 周边搜索请求参数
     * @return 归一化后的本页 POI 列表
     */
    List<AmapApiPoiVO> around(AmapApiAroundDTO dto);

    /**
     * 查询 POI 详情。
     *
     * @param poiId 高德 POI id
     * @return 详情，查不到返回 null
     */
    AmapApiPoiVO detail(String poiId);
}