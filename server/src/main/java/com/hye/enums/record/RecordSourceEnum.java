package com.hye.enums.record;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 吃过记录来源。
 */
@Getter
@AllArgsConstructor
public enum RecordSourceEnum {

    ROULETTE("roulette", "转盘抽签"),
    POI("poi", "堂食发牌"),
    MANUAL("manual", "手动记录"),
    AI_RECOMMEND("ai_recommend", "AI 推荐"),
    ;

    private final String code;
    private final String description;
}
