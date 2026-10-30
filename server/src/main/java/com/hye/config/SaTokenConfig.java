package com.hye.config;

import cn.dev33.satoken.interceptor.SaInterceptor;
import cn.dev33.satoken.stp.StpUtil;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Sa-Token 配置：登录校验拦截器与放行规则。
 */
@Configuration
public class SaTokenConfig implements WebMvcConfigurer {

    /**
     * 登录放行路径：登录、注册、刷新令牌、设备握手。
     */
    private static final String[] LOGIN_EXCLUDE_PATHS = {
            "/api/user/login", "/api/user/register", "/api/user/refresh", "/api/auth/handshake"
    };

    /**
     * 注册登录校验拦截器：/api/** 全部要求已登录。
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new SaInterceptor(handle -> StpUtil.checkLogin()))
                .addPathPatterns("/api/**")
                .excludePathPatterns(LOGIN_EXCLUDE_PATHS);
    }
}
