package com.hye.convert.favorite;

import cn.hutool.json.JSONUtil;
import com.hye.controller.favorite.vo.FavoriteVO;
import com.hye.entity.FavoriteDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;

@Mapper
public interface FavoriteConvert {

    FavoriteConvert INSTANCE = Mappers.getMapper(FavoriteConvert.class);

    /**
     * 收藏实体转 VO。
     *
     * @param favorite 收藏实体
     * @return 收藏 VO
     */
    FavoriteVO toVO(FavoriteDO favorite);

    /**
     * 收藏实体列表转 VO 列表。
     *
     * @param favorites 收藏实体列表
     * @return 收藏 VO 列表
     */
    List<FavoriteVO> toVOList(List<FavoriteDO> favorites);

    /**
     * 快照 JSON 转 Map，便于接口直接返回对象。
     *
     * @param extra 快照 JSON
     * @return 快照对象；为空时返回 null
     */
    default Map<String, Object> toExtra(String extra) {
        return StringUtils.hasText(extra) ? JSONUtil.parseObj(extra) : null;
    }
}
