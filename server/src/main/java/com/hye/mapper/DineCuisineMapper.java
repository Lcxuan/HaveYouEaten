package com.hye.mapper;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.hye.common.enums.CommonStatusEnum;
import com.hye.common.mapper.BaseMapperPlus;
import com.hye.entity.DineCuisineDO;

import java.util.List;

public interface DineCuisineMapper extends BaseMapperPlus<DineCuisineDO> {

    /**
     * 查询全部启用的出去吃菜系，按排序值升序。
     *
     * @return 启用菜系列表
     */
    default List<DineCuisineDO> selectEnabled() {
        return selectList(Wrappers.<DineCuisineDO>lambdaQuery()
                .eq(DineCuisineDO::getStatus, CommonStatusEnum.ENABLE.getCode())
                .orderByAsc(DineCuisineDO::getSort));
    }
}