package com.hye.service.restaurant;

import com.hye.entity.DineCuisineDO;

import java.util.List;

public interface DineCuisineService {

    /**
     * 查询全部启用的出去吃菜系，按排序值升序。
     *
     * @return 启用菜系列表
     */
    List<DineCuisineDO> getEnabledList();
}
