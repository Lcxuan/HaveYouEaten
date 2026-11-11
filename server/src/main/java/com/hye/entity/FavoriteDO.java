package com.hye.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.hye.common.entity.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("favorites")
public class FavoriteDO extends BaseDO {

    /**
     * 用户 id。
     */
    private Long userId;

    /**
     * 类型：recipe-菜谱，restaurant-餐厅。
     */
    private String targetType;

    /**
     * 目标 id（菜谱 id 或高德 POI id）。
     */
    private String targetId;

    /**
     * 名称冗余。
     */
    private String name;

    /**
     * 快照 JSON：餐厅收藏保存展示信息，打开详情时不再请求高德。
     */
    private String extra;
}
