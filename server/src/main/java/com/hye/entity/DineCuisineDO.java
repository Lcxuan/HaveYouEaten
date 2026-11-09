package com.hye.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.hye.common.entity.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

/**
 * 出去吃菜系字典实体（dine_cuisines 表），映射高德 POI 分类码。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "dine_cuisines", autoResultMap = true)
public class DineCuisineDO extends BaseDO {

    /**
     * 菜系名（川菜/粤菜/日料等）。
     */
    private String name;

    /**
     * 高德细分分类码数组，如 ["050105", "050106"]。
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> typecode;

    /**
     * 所属大类码，细分码召回不足时兜底，如 050100 中餐厅。
     */
    private String bigType;

    /**
     * 排序值，越小越靠前。
     */
    private Integer sort;

    /**
     * 是否启用：0-禁用，1-启用。
     */
    private Integer status;
}