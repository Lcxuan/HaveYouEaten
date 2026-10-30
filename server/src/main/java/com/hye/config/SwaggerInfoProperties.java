package com.hye.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 接口文档信息配置。
 */
@Data
@Component
@ConfigurationProperties(prefix = "swagger.info")
public class SwaggerInfoProperties {

    /**
     * 文档标题。
     */
    private String title;

    /**
     * 文档描述。
     */
    private String description;

    /**
     * 文档版本。
     */
    private String version;

    /**
     * 作者。
     */
    private String author;

    /**
     * 项目地址。
     */
    private String url;

    /**
     * 许可协议地址。
     */
    private String licenseUrl;
}
