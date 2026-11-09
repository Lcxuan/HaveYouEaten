package com.hye.convert.restaurant;

import com.hye.framework.amap.api.vo.AmapApiPoiVO;
import com.hye.controller.restaurant.vo.RestaurantVO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface RestaurantConvert {

    RestaurantConvert INSTANCE = Mappers.getMapper(RestaurantConvert.class);

    /**
     * 单个 POI 转成 VO
     *
     * @param poi 高德归一化结果
     * @return 餐厅卡片
     */
    RestaurantVO toVO(AmapApiPoiVO poi);

    /**
     * 批量转成 VO
     *
     * @param pois 高德归一化结果列表
     * @return 餐厅卡片列表
     */
    List<RestaurantVO> toVOList(List<AmapApiPoiVO> pois);
}
