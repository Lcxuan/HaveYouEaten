package com.hye.service.cuisine;

import com.hye.controller.cuisine.vo.CuisineVO;

import java.util.List;

public interface CuisineService {

    /**
     * 查询全部启用的菜系，按排序值升序。
     *
     * @return 启用的菜系列表
     */
    List<CuisineVO> getEnabledList();

    /**
     * 按菜系 id 查询菜系名称。
     *
     * @param cuisineId 菜系 id
     * @return 菜系名称；id 为空或字典中不存在时返回 null
     */
    String getCuisineName(Long cuisineId);
}
