package com.hye.enums.restaurant;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum RestaurantDrawRuleEnum {

    /**
     * 最近吃过的店排到队尾的天数。
     */
    RECENT_DAYS(3),
    ;

    private final int days;
}
