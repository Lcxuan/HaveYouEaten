package com.hye.config;

import com.hye.common.enums.WebFilterConstant;
import com.hye.common.resolver.HeaderBindArgumentResolver;
import com.hye.config.filter.CachedBodyFilter;
import com.hye.filter.auth.SignAuthFilter;
import com.hye.redis.auth.AuthRedis;
import jakarta.servlet.Filter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.List;

/**
 * Web 相关配置
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    /**
     * 注册跨域过滤器，优先处理浏览器的跨域预检请求。
     */
    @Bean
    public FilterRegistrationBean<CorsFilter> corsFilter() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowCredentials(true);
        configuration.addAllowedOriginPattern("*");
        configuration.addAllowedHeader("*");
        configuration.addAllowedMethod("*");

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return createFilterBean(new CorsFilter(source), WebFilterConstant.CORS_FILTER_ORDER);
    }

    /**
     * 注册请求体缓存过滤器
     */
    @Bean
    public FilterRegistrationBean<CachedBodyFilter> cachedBodyFilter() {
        return createFilterBean(new CachedBodyFilter(), WebFilterConstant.CACHED_BODY_FILTER_ORDER);
    }

    /**
     * 注册签名鉴权过滤器
     */
    @Bean
    public FilterRegistrationBean<SignAuthFilter> signAuthFilter(AuthProperties authProperties, AuthRedis authRedis) {
        return createFilterBean(new SignAuthFilter(authProperties, authRedis), WebFilterConstant.SIGN_AUTH_FILTER_ORDER);
    }

    /**
     * 注册请求头参数解析器，支持 DTO 字段从请求头自动装配。
     */
    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(new HeaderBindArgumentResolver());
    }

    /**
     * 创建过滤器注册对象。
     *
     * @param filter 过滤器
     * @param order  执行优先级
     */
    private static <T extends Filter> FilterRegistrationBean<T> createFilterBean(T filter, int order) {
        FilterRegistrationBean<T> bean = new FilterRegistrationBean<>(filter);
        bean.setOrder(order);
        return bean;
    }
}
