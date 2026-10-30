package com.hye.common.utils;

import cn.dev33.satoken.stp.StpUtil;

/**
 * 当前登录用户上下文：任意位置静态获取。
 *
 * <p>底层基于 Sa-Token 请求上下文，登录态跟随当前请求线程，各请求相互隔离、
 * 无共享可变状态，多线程下天然安全。在非请求线程（如异步任务）中调用视为未登录，
 * 返回 null。</p>
 */
public final class LoginContextHolder {

    private LoginContextHolder() {
    }

    /**
     * 获取当前登录用户 id，未登录或非请求线程返回 null。
     */
    public static Long getUserId() {
        try {
            Object loginId = StpUtil.getLoginIdDefaultNull();
            return loginId == null ? null : Long.valueOf(loginId.toString());
        } catch (Exception e) {
            // 非 Web 线程中没有请求上下文，视为未登录
            return null;
        }
    }
}
