package com.hye.framework.amap.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 高德周边搜索分页参数。
 */
@Getter
@RequiredArgsConstructor
public enum AmapPageSizeEnum {

    /**
     * 单页固定返回的条数
     */
    DEFAULT(25),

    /**
     * 单次发牌最多翻的页数
     */
    MAX_PAGES(2);

    private final int value;
}
