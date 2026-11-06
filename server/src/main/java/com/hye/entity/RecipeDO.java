package com.hye.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.hye.common.entity.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

/**
 * 菜谱实体（recipes 表）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "recipes", autoResultMap = true)
public class RecipeDO extends BaseDO {

    /**
     * 菜名。
     */
    private String name;

    /**
     * 简介。
     */
    private String description;

    /**
     * 菜系（川菜/粤菜/家常菜等）。
     */
    private String cuisine;

    /**
     * 难度：1-简单，2-中等，3-困难。
     */
    private Integer difficulty;

    /**
     * 烹饪时长（分钟）。
     */
    private Integer cookMinutes;

    /**
     * 口味等标签。
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> tags;

    /**
     * 食材清单。
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<RecipeIngredientDO> ingredients;

    /**
     * 做法步骤。
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<RecipeStepDO> steps;

    /**
     * AI 生成/改写的字段名数组：description / ingredients / steps / image_url。
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> aigcFields;

    /**
     * 封面图地址。
     */
    private String imageUrl;

    /**
     * 来源：ai-AI 生成，import-开源菜谱导入，manual-人工录入。
     */
    private String source;

    /**
     * 是否上架：0-下架，1-上架。
     */
    private Integer enabled;
}
