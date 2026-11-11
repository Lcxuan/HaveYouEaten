package com.hye.common;

import cn.dev33.satoken.exception.NotLoginException;
import com.hye.common.enums.exception.BusinessException;
import com.hye.common.enums.exception.GlobalErrorCodeConstants;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.BindException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/**
 * 全局异常处理器，统一返回 Result 响应结构。
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 处理业务异常，统一返回 HTTP 200，由业务码区分错误。
     */
    @ExceptionHandler(BusinessException.class)
    public Result<Void> handleBusinessException(BusinessException exception) {
        log.warn("业务异常：{}", exception.getMessage());
        return Result.error(exception.getErrorCode(), exception.getMessage());
    }

    /**
     * 处理 Sa-Token 未登录异常。
     */
    @ExceptionHandler(NotLoginException.class)
    public Result<Void> handleNotLoginException(NotLoginException exception) {
        log.warn("未登录访问：{}", exception.getMessage());
        return Result.error(GlobalErrorCodeConstants.UNAUTHORIZED, "未登录或登录已失效");
    }

    /**
     * 处理请求参数校验或绑定失败。
     */
    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public Result<Void> handleValidationException(Exception exception) {
        log.warn("请求参数校验失败：{}", exception.getMessage());
        BindingResult bindingResult = exception instanceof MethodArgumentNotValidException methodException
                ? methodException.getBindingResult()
                : ((BindException) exception).getBindingResult();
        FieldError fieldError = bindingResult.getFieldError();
        String message = fieldError == null
                ? GlobalErrorCodeConstants.BAD_REQUEST.getMsg()
                : fieldError.getDefaultMessage();
        return Result.error(GlobalErrorCodeConstants.BAD_REQUEST.getCode(), message);
    }

    /**
     * 处理方法参数上的校验失败（如 @RequestParam 上的 @Pattern）。
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public Result<Void> handleConstraintViolationException(ConstraintViolationException exception) {
        log.warn("请求参数校验失败：{}", exception.getMessage());
        String message = exception.getConstraintViolations().stream()
                .findFirst()
                .map(ConstraintViolation::getMessage)
                .orElse(GlobalErrorCodeConstants.BAD_REQUEST.getMsg());
        return Result.error(GlobalErrorCodeConstants.BAD_REQUEST.getCode(), message);
    }

    /**
     * 处理不支持的 HTTP 请求方法。
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public Result<Void> handleHttpRequestMethodNotSupportedException(
            HttpRequestMethodNotSupportedException exception) {
        log.warn("不支持的请求方法：{}", exception.getMessage());
        return Result.error(GlobalErrorCodeConstants.METHOD_NOT_ALLOWED);
    }

    /**
     * 处理不存在的静态资源请求。
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public Result<Void> handleNoResourceFoundException(NoResourceFoundException exception) {
        return Result.error(GlobalErrorCodeConstants.NOT_FOUND);
    }

    /**
     * 兜底处理未预期的系统异常。
     */
    @ExceptionHandler(Exception.class)
    public Result<Void> handleException(Exception exception) {
        log.error("未处理的系统异常", exception);
        return Result.error(GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR);
    }
}
