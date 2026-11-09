package com.hye.convert.restaurant;

import com.hye.controller.restaurant.vo.DineCuisineVO;
import com.hye.entity.DineCuisineDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface DineCuisineConvert {

    DineCuisineConvert INSTANCE = Mappers.getMapper(DineCuisineConvert.class);

    /**
     * 菜系实体转字典项 VO。
     *
     * @param cuisine 菜系实体
     * @return 菜系字典项
     */
    DineCuisineVO toVO(DineCuisineDO cuisine);

    /**
     * 菜系实体列表转字典项列表。
     *
     * @param cuisines 菜系实体列表
     * @return 菜系字典项列表
     */
    List<DineCuisineVO> toVOList(List<DineCuisineDO> cuisines);
}