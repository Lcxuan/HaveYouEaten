package com.hye.redis.restaurant;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.hye.config.AppProperties;
import com.hye.framework.amap.api.vo.AmapApiPoiVO;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.List;

@Component
public class RestaurantRedis {

    /**
     * 附近餐厅 POI key 段，完整 key 为 {app}:restaurant:poi:{lng|lat|radius|types|keywords}。
     */
    private static final String POI_KEY = "restaurant:poi:";

    /**
     * POI 缓存过期时间。
     */
    private static final Duration POI_TTL = Duration.ofMinutes(5);

    private final String keyPrefix;

    private final StringRedisTemplate stringRedisTemplate;

    public RestaurantRedis(AppProperties appProperties, StringRedisTemplate stringRedisTemplate) {
        this.keyPrefix = appProperties.getName() + ":";
        this.stringRedisTemplate = stringRedisTemplate;
    }

    /**
     * 读取附近餐厅 POI 缓存。
     *
     * @param types    高德分类码
     * @param keywords 关键词
     * @param lng      经度
     * @param lat      纬度
     * @param radius   搜索半径
     * @return 缓存的 POI 列表，未命中返回 null
     */
    public List<AmapApiPoiVO> getPois(String types, String keywords, double lng, double lat, int radius) {
        String cached = stringRedisTemplate.opsForValue().get(poiKey(types, keywords, lng, lat, radius));
        return StrUtil.isBlank(cached) ? null : JSONUtil.toList(cached, AmapApiPoiVO.class);
    }

    /**
     * 写入附近餐厅 POI 缓存，TTL 到期自动清理。
     *
     * @param types    高德分类码
     * @param keywords 关键词
     * @param lng      经度
     * @param lat      纬度
     * @param radius   搜索半径
     * @param pois     POI 列表
     */
    public void setPois(String types, String keywords, double lng, double lat, int radius, List<AmapApiPoiVO> pois) {
        stringRedisTemplate.opsForValue().set(
                poiKey(types, keywords, lng, lat, radius), JSONUtil.toJsonStr(pois), POI_TTL);
    }

    /**
     * 拼接完整 key：{app}:{段}:{坐标|半径|分类码|关键词}。
     */
    private String poiKey(String types, String keywords, double lng, double lat, int radius) {
        return keyPrefix + POI_KEY
                + String.format("%.4f|%.4f|%d|%s|%s", lng, lat, radius, types, keywords);
    }
}
