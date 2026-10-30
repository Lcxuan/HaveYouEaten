package com.hye;

import org.junit.jupiter.api.Test;

import java.security.SecureRandom;
import java.util.HexFormat;

/**
 * 鉴权凭证生成：运行后打印可直接使用的 AUTH_APP_KEY / AUTH_SECRET
 */
class AuthKeyGeneratorTest {

    /**
     * APP_KEY 字节数：32 位十六进制字符，握手标识用。
     */
    private static final int APP_KEY_BYTES = 16;

    /**
     * SECRET 字节数：64 位十六进制字符（256bit 熵），与 HMAC-SHA256 强度匹配。
     */
    private static final int SECRET_BYTES = 32;

    @Test
    void generateAuthKeys() {
        System.out.println("AUTH_APP_KEY=" + randomHex(APP_KEY_BYTES));
        System.out.println("AUTH_SECRET=" + randomHex(SECRET_BYTES));
    }

    /**
     * 生成指定字节数的安全随机十六进制串。
     */
    private static String randomHex(int byteLength) {
        byte[] bytes = new byte[byteLength];
        new SecureRandom().nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }
}
