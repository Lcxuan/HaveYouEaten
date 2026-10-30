package com.hye.common.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 标记 DTO 字段来源于指定 HTTP 请求头，配合 {@code HeaderBindArgumentResolver} 自动装配。
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface HeaderBindField {

    /**
     * 请求头名称。
     */
    String value();
}
