package com.hye.common.utils;

import java.time.LocalDateTime;

/**
 * 时间工具
 */
public final class DateUtils {

    private DateUtils() {
    }

    /**
     * 当前时间往前推指定天数。
     *
     * @param days 天数
     * @return 时间点
     */
    public static LocalDateTime nowMinusDays(int days) {
        return LocalDateTime.now().minusDays(days);
    }
}
