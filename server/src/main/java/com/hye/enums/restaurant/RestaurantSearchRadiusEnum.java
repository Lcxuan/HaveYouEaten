package com.hye.enums.restaurant;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum RestaurantSearchRadiusEnum {

    /**
     * 默认半径。
     */
    DEFAULT(3000),

    /**
     * 最小半径。
     */
    MIN(500),

    /**
     * 最大半径。
     */
    MAX(5000);

    private final int value;
}