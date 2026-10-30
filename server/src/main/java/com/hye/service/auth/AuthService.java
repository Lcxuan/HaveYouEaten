package com.hye.service.auth;

import com.hye.controller.auth.dto.AuthHandshakeDTO;
import com.hye.controller.auth.vo.AuthHandshakeVO;

/**
 * 认证业务接口。
 */
public interface AuthService {

    /**
     * App 握手，校验通过后签发短期访问令牌。
     *
     * @param dto 握手凭证（appKey、timestamp、nonce）
     * @return token 及其有效期（秒）
     */
    AuthHandshakeVO handshake(AuthHandshakeDTO dto);
}
