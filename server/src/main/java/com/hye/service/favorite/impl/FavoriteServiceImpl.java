package com.hye.service.favorite.impl;

import cn.hutool.json.JSONUtil;
import com.hye.common.pojo.PageParam;
import com.hye.common.pojo.PageResult;
import com.hye.common.utils.LoginContextHolder;
import com.hye.controller.favorite.dto.FavoriteCreateDTO;
import com.hye.controller.favorite.vo.FavoriteVO;
import com.hye.convert.favorite.FavoriteConvert;
import com.hye.entity.FavoriteDO;
import com.hye.enums.favorite.FavoriteTargetTypeEnum;
import com.hye.mapper.FavoriteMapper;
import com.hye.service.favorite.FavoriteService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

@Service
public class FavoriteServiceImpl implements FavoriteService {

    /**
     * 名称列长度。
     */
    private static final int NAME_MAX_LENGTH = 64;

    @Resource
    private FavoriteMapper favoriteMapper;

    @Override
    public Long add(FavoriteCreateDTO dto) {
        FavoriteTargetTypeEnum targetType = FavoriteTargetTypeEnum.of(dto.getTargetType());
        Long userId = LoginContextHolder.getUserId();

        // 已收藏过则直接返回，避免重复插入
        FavoriteDO existing = favoriteMapper.selectByTarget(userId, targetType.getCode(), dto.getTargetId());
        if (existing != null) {
            return existing.getId();
        }

        FavoriteDO favorite = new FavoriteDO();
        favorite.setUserId(userId);
        favorite.setTargetType(targetType.getCode());
        favorite.setTargetId(dto.getTargetId());
        favorite.setName(truncate(dto.getName(), NAME_MAX_LENGTH));
        if (dto.getExtra() != null && !dto.getExtra().isEmpty()) {
            favorite.setExtra(JSONUtil.toJsonStr(dto.getExtra()));
        }
        favoriteMapper.insert(favorite);
        return favorite.getId();
    }

    @Override
    public void remove(String targetType, String targetId) {
        FavoriteTargetTypeEnum type = FavoriteTargetTypeEnum.of(targetType);
        favoriteMapper.deleteByTarget(LoginContextHolder.getUserId(), type.getCode(), targetId);
    }

    @Override
    public PageResult<FavoriteVO> list(String targetType, PageParam pageParam) {
        FavoriteTargetTypeEnum type = FavoriteTargetTypeEnum.of(targetType);
        PageResult<FavoriteDO> result = favoriteMapper.selectPageByType(
                LoginContextHolder.getUserId(), type.getCode(), pageParam);
        return new PageResult<>(FavoriteConvert.INSTANCE.toVOList(result.getList()), result.getTotal());
    }

    @Override
    public boolean status(String targetType, String targetId) {
        FavoriteTargetTypeEnum type = FavoriteTargetTypeEnum.of(targetType);
        return favoriteMapper.selectByTarget(LoginContextHolder.getUserId(), type.getCode(), targetId) != null;
    }

    /**
     * 名称列长度为 64，超长时截断避免写入失败。
     */
    private String truncate(String value, int maxLength) {
        return value.length() > maxLength ? value.substring(0, maxLength) : value;
    }
}
