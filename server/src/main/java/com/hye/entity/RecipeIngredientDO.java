package com.hye.entity;

import lombok.Data;

/**
 * 食材项（recipes.ingredients 数组元素）。
 */
@Data
public class RecipeIngredientDO {

    /**
     * 食材名。
     */
    private String name;

    /**
     * 用量，如 "500g"。
     */
    private String amount;
}
