package com.hye.enums.favorite;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum FavoriteTargetTypeEnum {

    RECIPE("recipe", "菜谱"),
    RESTAURANT("restaurant", "餐厅"),
    ;

    private final String code;
    private final String description;

    /**
     * 所有合法类型编码，供参数校验注解复用。
     */
    public static final String CODES_REGEXP = "recipe|restaurant";

    /**
     * 按 code 查找枚举。
     *
     * @param code 类型编码
     * @return 匹配的枚举；不支持时返回 null
     */
    public static FavoriteTargetTypeEnum of(String code) {
        for (FavoriteTargetTypeEnum value : values()) {
            if (value.code.equals(code)) {
                return value;
            }
        }
        return null;
    }
}
