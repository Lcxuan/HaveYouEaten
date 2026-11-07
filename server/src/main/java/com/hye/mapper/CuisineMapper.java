package com.hye.mapper;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.hye.common.enums.CommonStatusEnum;
import com.hye.common.mapper.BaseMapperPlus;
import com.hye.entity.CuisineDO;

import java.util.List;

public interface CuisineMapper extends BaseMapperPlus<CuisineDO> {

    /**
     * 查询全部启用的菜系，按排序值升序。
     *
     * @return 启用菜系列表
     */
    default List<CuisineDO> selectEnabled() {
        return selectList(Wrappers.<CuisineDO>lambdaQuery()
                .eq(CuisineDO::getStatus, CommonStatusEnum.ENABLE.getCode())
                .orderByAsc(CuisineDO::getSort));
    }
}
