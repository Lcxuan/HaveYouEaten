package com.hye.service.restaurant;

import com.hye.controller.restaurant.dto.RestaurantDeckDTO;
import com.hye.controller.restaurant.vo.DineCuisineVO;
import com.hye.controller.restaurant.vo.RestaurantDeckVO;
import com.hye.controller.restaurant.vo.RestaurantVO;

import java.util.List;

public interface RestaurantService {

    /**
     * 查询全部启用的出去吃菜系，供筛选面板与抽签使用。
     *
     * @return 菜系列表
     */
    List<DineCuisineVO> getDineCuisines();

    /**
     * 发一叠餐厅卡：先抽一个菜系，再拉取该菜系附近的店。
     *
     * @param dto 位置与筛选条件
     * @return 菜系、候选池大小与已排序的卡片
     */
    RestaurantDeckVO deck(RestaurantDeckDTO dto);

    /**
     * 餐厅详情。
     *
     * @param poiId 高德 POI id
     * @return 餐厅卡片
     */
    RestaurantVO detail(String poiId);
}
