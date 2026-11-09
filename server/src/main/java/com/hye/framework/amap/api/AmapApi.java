package com.hye.framework.amap.api;

import com.hye.framework.amap.api.dto.AmapApiAroundDTO;
import com.hye.framework.amap.api.vo.AmapApiPoiVO;
import com.hye.framework.amap.service.AmapService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class AmapApi {

    @Resource
    private AmapService amapService;

    /**
     * 按分类码与关键词搜索周边餐饮。
     */
    public List<AmapApiPoiVO> around(AmapApiAroundDTO dto) {
        return amapService.around(dto);
    }

    /**
     * 查询 POI 详情。
     */
    public AmapApiPoiVO detail(String poiId) {
        return amapService.detail(poiId);
    }
}