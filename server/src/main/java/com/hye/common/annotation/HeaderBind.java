package com.hye.common.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 标记 Controller 参数为"请求头绑定对象"：参数类型的字段通过
 * {@link HeaderBindField} 声明头名，由 HeaderBindArgumentResolver 自动装配。
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface HeaderBind {
}
