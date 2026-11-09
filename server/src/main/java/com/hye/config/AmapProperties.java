package com.hye.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 高德 Web 服务配置。
 *
 */
@Data
@Component
@ConfigurationProperties(prefix = "amap")
public class AmapProperties {

    /**
     * 高德 Web 服务 key。
     */
    private String key;

    /**
     * 高德接口根地址。
     */
    private String baseUrl = "https://restapi.amap.com";

    /**
     * 单次请求超时（毫秒）。
     */
    private int timeout = 3000;
}
