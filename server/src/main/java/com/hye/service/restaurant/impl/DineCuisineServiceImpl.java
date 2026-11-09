package com.hye.service.restaurant.impl;

import com.hye.entity.DineCuisineDO;
import com.hye.mapper.DineCuisineMapper;
import com.hye.service.restaurant.DineCuisineService;
import jakarta.annotation.Resource;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DineCuisineServiceImpl implements DineCuisineService {

    @Resource
    private DineCuisineMapper dineCuisineMapper;

    @Override
    @Cacheable(cacheNames = "dineCuisine", key = "'enabled'")
    public List<DineCuisineDO> getEnabledList() {
        return dineCuisineMapper.selectEnabled();
    }
}
