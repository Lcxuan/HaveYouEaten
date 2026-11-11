package com.hye.service.favorite;

import com.hye.common.pojo.PageParam;
import com.hye.common.pojo.PageResult;
import com.hye.controller.favorite.dto.FavoriteCreateDTO;
import com.hye.controller.favorite.vo.FavoriteVO;

public interface FavoriteService {

    /**
     * 新增收藏
     *
     * @param dto 收藏参数
     * @return 收藏 id
     */
    Long add(FavoriteCreateDTO dto);

    /**
     * 取消收藏。
     *
     * @param targetType 类型：recipe / restaurant
     * @param targetId   目标 id
     */
    void remove(String targetType, String targetId);

    /**
     * 分页查询当前用户某一类型的收藏。
     *
     * @param targetType 类型：recipe / restaurant
     * @param pageParam  分页参数
     * @return 分页收藏
     */
    PageResult<FavoriteVO> list(String targetType, PageParam pageParam);

    /**
     * 查询当前用户是否已收藏某个目标。
     *
     * @param targetType 类型：recipe / restaurant
     * @param targetId   目标 id
     * @return 是否已收藏
     */
    boolean status(String targetType, String targetId);
}
