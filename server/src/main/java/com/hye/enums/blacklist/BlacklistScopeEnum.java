package com.hye.enums.blacklist;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum BlacklistScopeEnum {

    CUISINE("cuisine", "菜系"),
    POI("poi", "餐厅"),
    RECIPE("recipe", "菜谱"),
    ;

    /**
     * 所有粒度编码，供入参校验使用。
     */
    public static final String CODES_REGEXP = "cuisine|poi|recipe";

    private final String code;
    private final String description;

    /**
     * 按 code 查找枚举。
     *
     * @param code 粒度编码
     * @return 匹配的枚举；不支持时返回 null
     */
    public static BlacklistScopeEnum of(String code) {
        for (BlacklistScopeEnum value : values()) {
            if (value.code.equals(code)) {
                return value;
            }
        }
        return null;
    }
}
