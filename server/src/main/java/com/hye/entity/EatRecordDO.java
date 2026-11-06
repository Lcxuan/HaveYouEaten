package com.hye.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.hye.common.entity.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 吃过记录实体（eat_records 表）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("eat_records")
public class EatRecordDO extends BaseDO {

    /**
     * 用户 id。
     */
    private Long userId;

    /**
     * 菜谱 id（在家吃时填写）。
     */
    private Long recipeId;

    /**
     * 高德 POI id（出去吃时填写）。
     */
    private String poiId;

    /**
     * 名称冗余（菜名/店名，防源数据变化）。
     */
    private String name;

    /**
     * 来源：roulette-抽签，manual-手动，ai_recommend-AI 推荐。
     */
    private String source;

    /**
     * 吃饭时间。
     */
    private LocalDateTime eatenAt;

    /**
     * 备注。
     */
    private String remark;
}
