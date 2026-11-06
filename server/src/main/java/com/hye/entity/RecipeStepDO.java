package com.hye.entity;

import lombok.Data;

/**
 * 做法步骤项（recipes.steps 数组元素）。
 */
@Data
public class RecipeStepDO {

    /**
     * 序号。
     */
    private Integer order;

    /**
     * 步骤描述。
     */
    private String text;
}
