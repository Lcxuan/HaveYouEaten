package com.hye.common.utils;

import cn.hutool.http.HttpUtil;

import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

public final class HttpUtils {

    private HttpUtils() {
    }

    /**
     * 发起 GET 请求并返回响应体字符串。
     *
     * @param url     请求地址（不含 query）
     * @param query   要拼接到 URL 的 query 参数
     * @param timeout 超时时间（毫秒）
     * @return 响应体
     */
    public static String get(String url, Map<String, ?> query, int timeout) {
        Map<String, Object> form = new LinkedHashMap<>(query);
        return HttpUtil.createGet(HttpUtil.urlWithForm(url, form, StandardCharsets.UTF_8, false))
                .timeout(timeout)
                .execute()
                .body();
    }
}