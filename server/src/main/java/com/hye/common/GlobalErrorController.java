package com.hye.common;

import com.hye.enums.exception.GlobalErrorCodeConstants;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.web.servlet.error.ErrorController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 接管 Spring Boot 默认 /error：Filter 链等处漏网的异常统一转为 HTTP 200 + Result 结构。
 */
@RestController
public class GlobalErrorController implements ErrorController {

    private static final String STATUS_CODE_ATTRIBUTE = "jakarta.servlet.error.status_code";

    /**
     * 容器转发过来的错误统一按业务码返回。
     */
    @RequestMapping("/error")
    public Result<Void> error(HttpServletRequest request) {
        return Result.error(resolveErrorCode(request));
    }

    /**
     * 将容器状态码映射为业务错误码，未知状态一律按系统异常处理。
     */
    private GlobalErrorCodeConstants resolveErrorCode(HttpServletRequest request) {
        Object status = request.getAttribute(STATUS_CODE_ATTRIBUTE);
        int code = status instanceof Integer ? (Integer) status : 0;
        return switch (code) {
            case 404 -> GlobalErrorCodeConstants.NOT_FOUND;
            case 405 -> GlobalErrorCodeConstants.METHOD_NOT_ALLOWED;
            default -> GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR;
        };
    }
}
