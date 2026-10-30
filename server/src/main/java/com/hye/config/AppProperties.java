package com.hye.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 应用基础配置。
 */
@Data
@Component
@ConfigurationProperties(prefix = "hye")
public class AppProperties {

    /**
     * 应用名，同时作为 Redis key 前缀（多应用共享 Redis 时隔离 key）。
     */
    private String name = "hye";
}
