package com.hye.framework.amap.exception;

import com.hye.common.enums.exception.BusinessException;
import com.hye.common.enums.exception.ErrorCode;

/**
 * 高德组件业务异常，继承通用业务异常以复用统一异常处理链路。
 */
public class AmapException extends BusinessException {

    public AmapException(ErrorCode errorCode) {
        super(errorCode);
    }

    public AmapException(ErrorCode errorCode, String message) {
        super(errorCode, message);
    }
}