package com.hye.enums.recipe;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 抽签规则参数。
 */
@Getter
@AllArgsConstructor
public enum RecipeDrawRuleEnum {

    /**
     * 去重回看窗口（天）：最近 N 天吃过的不再抽中。
     */
    RECENT_DAYS(3),
    ;

    private final int days;
}
