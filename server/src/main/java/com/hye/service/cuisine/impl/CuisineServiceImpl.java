package com.hye.service.cuisine.impl;

import com.hye.controller.cuisine.vo.CuisineVO;
import com.hye.convert.cuisine.CuisineConvert;
import com.hye.entity.CuisineDO;
import com.hye.mapper.CuisineMapper;
import com.hye.service.cuisine.CuisineService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CuisineServiceImpl implements CuisineService {

    @Resource
    private CuisineMapper cuisineMapper;

    @Override
    public List<CuisineVO> getEnabledList() {
        List<CuisineDO> cuisines = cuisineMapper.selectEnabled();
        return CuisineConvert.INSTANCE.toVOList(cuisines);
    }

    @Override
    public String getCuisineName(Long cuisineId) {
        if (cuisineId == null) {
            return null;
        }
        CuisineDO cuisine = cuisineMapper.selectById(cuisineId);
        return cuisine == null ? null : cuisine.getName();
    }
}
