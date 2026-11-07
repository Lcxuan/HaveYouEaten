package com.hye.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.hye.common.entity.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

/**
 * 菜系字典实体（cuisines 表）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "cuisines", autoResultMap = true)
public class CuisineDO extends BaseDO {

    /**
     * 菜系名（家常菜/川菜/粤菜等）。
     */
    private String name;

    /**
     * 适用餐段：1-早餐，2-午餐，3-晚餐，4-夜宵
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<Integer> mealPeriods;

    /**
     * 排序值，越小越靠前。
     */
    private Integer sort;

    /**
     * 是否启用：0-禁用，1-启用。
     */
    private Integer status;
}
