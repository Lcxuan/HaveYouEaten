package com.hye.common.utils;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * 签名工具：HMAC-SHA256 / SHA-256 / 时间戳窗口校验。
 *
 * <p>签名串格式（换行分隔）：</p>
 */
public final class SignUtils {

    private static final char[] HEX = "0123456789abcdef".toCharArray();

    private static final String EMPTY_BODY_SHA256 =
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

    private SignUtils() {
    }

    /**
     * 计算 SHA-256 十六进制摘要；空串返回预置常量。
     */
    public static String sha256Hex(String data) {
        if (data == null || data.isEmpty()) {
            return EMPTY_BODY_SHA256;
        }
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return toHex(digest.digest(data.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 不可用", e);
        }
    }

    /**
     * 计算 HMAC-SHA256 十六进制签名。
     */
    public static String hmacSha256Hex(String secret, String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return toHex(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("HMAC-SHA256 计算失败", e);
        }
    }

    /**
     * 常量时间比较，防时序攻击。
     */
    public static boolean safeEquals(String a, String b) {
        if (a == null || b == null) {
            return false;
        }
        return MessageDigest.isEqual(
                a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * 时间戳（毫秒）是否在允许窗口内。
     */
    public static boolean isTimestampValid(String timestampMillis, long windowSeconds) {
        try {
            long ts = Long.parseLong(timestampMillis);
            long deviation = Math.abs(System.currentTimeMillis() - ts);
            return deviation <= windowSeconds * 1000;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    /**
     * 拼接待签名串。
     */
    public static String buildStringToSign(String method, String path, String query,
                                           String timestamp, String nonce, String bodySha256) {
        return String.join("\n",
                method, path, query == null ? "" : query, timestamp, nonce, bodySha256);
    }

    private static String toHex(byte[] bytes) {
        char[] out = new char[bytes.length * 2];
        for (int i = 0; i < bytes.length; i++) {
            int v = bytes[i] & 0xFF;
            out[i * 2] = HEX[v >>> 4];
            out[i * 2 + 1] = HEX[v & 0x0F];
        }
        return new String(out);
    }
}
