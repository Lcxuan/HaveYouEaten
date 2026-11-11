package com.hye.convert.blacklist;

import com.hye.controller.blacklist.vo.BlacklistVO;
import com.hye.entity.BlacklistDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface BlacklistConvert {

    BlacklistConvert INSTANCE = Mappers.getMapper(BlacklistConvert.class);

    /**
     * 黑名单实体转 VO。
     *
     * @param blacklist 黑名单实体
     * @return 黑名单 VO
     */
    BlacklistVO toVO(BlacklistDO blacklist);

    /**
     * 黑名单实体列表转 VO 列表。
     *
     * @param blacklists 黑名单实体列表
     * @return 黑名单 VO 列表
     */
    List<BlacklistVO> toVOList(List<BlacklistDO> blacklists);
}
