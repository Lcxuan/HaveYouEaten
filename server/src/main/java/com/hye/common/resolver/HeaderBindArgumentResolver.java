package com.hye.common.resolver;

import com.hye.common.annotation.HeaderBind;
import com.hye.common.annotation.HeaderBindField;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.BeanUtils;
import org.springframework.core.MethodParameter;
import org.springframework.core.convert.ConversionService;
import org.springframework.core.convert.support.DefaultConversionService;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import java.lang.reflect.Field;
import java.util.List;

/**
 * 请求头到 DTO 的参数解析器：将标注 {@link HeaderBind} 的 DTO 字段从请求头自动装配。
 *
 * <p>Spring MVC 原生仅支持 query/form 绑定到对象，请求头无法自动装配，
 * 本解析器补齐该能力，使 Controller 入参保持对象化。</p>
 */
public class HeaderBindArgumentResolver implements HandlerMethodArgumentResolver {

    private static final ConversionService CONVERSION_SERVICE = new DefaultConversionService();

    @Override
    public boolean supportsParameter(MethodParameter parameter) {
        return parameter.hasParameterAnnotation(HeaderBind.class);
    }

    @Override
    public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
                                  NativeWebRequest webRequest, WebDataBinderFactory binderFactory) throws Exception {
        Class<?> type = parameter.getParameterType();
        Object instance = BeanUtils.instantiateClass(type);
        HttpServletRequest request = webRequest.getNativeRequest(HttpServletRequest.class);
        for (Field field : type.getDeclaredFields()) {
            HeaderBindField headerBind = field.getAnnotation(HeaderBindField.class);
            if (headerBind == null || request == null) {
                continue;
            }
            String value = request.getHeader(headerBind.value());
            if (value != null) {
                field.setAccessible(true);
                field.set(instance, CONVERSION_SERVICE.convert(value, field.getType()));
            }
        }
        return instance;
    }
}
