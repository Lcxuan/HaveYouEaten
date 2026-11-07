package com.hye.convert.cuisine;

import com.hye.controller.cuisine.vo.CuisineVO;
import com.hye.entity.CuisineDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * 菜系对象转换器。
 */
@Mapper
public interface CuisineConvert {

    CuisineConvert INSTANCE = Mappers.getMapper(CuisineConvert.class);

    /**
     * 菜系实体转字典项 VO。
     *
     * @param cuisine 菜系实体
     * @return 菜系字典项
     */
    CuisineVO toVO(CuisineDO cuisine);

    /**
     * 菜系实体列表转字典项列表。
     *
     * @param cuisines 菜系实体列表
     * @return 菜系字典项列表
     */
    List<CuisineVO> toVOList(List<CuisineDO> cuisines);
}
