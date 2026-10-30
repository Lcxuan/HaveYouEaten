package com.hye.config;

import com.hye.controller.auth.AuthController;
import com.hye.enums.auth.AuthHeaderConstants;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.parameters.Parameter;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.HandlerMethod;

/**
 * Swagger 接口文档配置。
 */
@Configuration
public class SwaggerConfig {

    /**
     * 创建 API 接口文档。
     *
     * @param properties 文档信息配置
     * @return OpenAPI 配置
     */
    @Bean
    public OpenAPI openApi(SwaggerInfoProperties properties) {
        return new OpenAPI()
                .info(new Info()
                        .title(properties.getTitle())
                        .description(properties.getDescription())
                        .version(properties.getVersion())
                        .contact(new Contact().name(properties.getAuthor()).url(properties.getUrl()))
                        .license(new License().name("许可协议").url(properties.getLicenseUrl())));
    }

    /**
     * App 端接口文档分组，统一补充签名鉴权请求头。
     *
     * @return App 端接口分组
     */
    @Bean
    public GroupedOpenApi appGroupedOpenApi() {
        return GroupedOpenApi.builder()
                .group("App 接口")
                .pathsToMatch("/api/**")
                .addOperationCustomizer((operation, handlerMethod) -> {
                    addAuthHeaders(operation, handlerMethod);
                    return operation;
                })
                .build();
    }

    /**
     * 补充鉴权请求头：所有接口带签名四件套，握手接口额外带 X-App-Key。
     */
    private static void addAuthHeaders(Operation operation, HandlerMethod handlerMethod) {
        operation.addParametersItem(header(AuthHeaderConstants.ACCESS_TOKEN, "访问令牌"))
                .addParametersItem(header(AuthHeaderConstants.TIMESTAMP, "时间戳（毫秒）"))
                .addParametersItem(header(AuthHeaderConstants.NONCE, "一次性随机数"))
                .addParametersItem(header(AuthHeaderConstants.SIGN, "HMAC-SHA256 签名"));
        if (handlerMethod.getBeanType() == AuthController.class) {
            operation.addParametersItem(header(AuthHeaderConstants.APP_KEY, "握手凭证（仅握手接口需要）"));
        }
    }

    /**
     * 构建请求头参数。
     */
    private static Parameter header(String name, String description) {
        return new Parameter()
                .name(name)
                .description(description)
                .in("header")
                .required(false);
    }
}
