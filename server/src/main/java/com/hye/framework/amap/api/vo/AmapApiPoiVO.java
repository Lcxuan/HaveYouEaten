package com.hye.framework.amap.api.vo;

import lombok.Data;

import java.util.List;

@Data
public class AmapApiPoiVO {

    /**
     * 高德 POI id。
     */
    private String poiId;

    /**
     * 门店名称。
     */
    private String name;

    /**
     * 门店地址。
     */
    private String address;

    /**
     * 距查询点距离（米），未传 location 时为空。
     */
    private Integer distance;

    /**
     * 人均消费（元），可能缺失。
     */
    private Double cost;

    /**
     * 评分，可能缺失。
     */
    private Double rating;

    /**
     * 高德分类码，排查误召回时用。
     */
    private String typecode;

    /**
     * 店铺标签，来自 business.tag / keytag 切分。
     */
    private List<String> tags;

    /**
     * 经度（GCJ-02）。
     */
    private Double lng;

    /**
     * 纬度（GCJ-02）。
     */
    private Double lat;

    /**
     * 联系电话。
     */
    private String tel;

    /**
     * 今日营业时间，如 10:00-22:00。
     */
    private String openTime;

    /**
     * 入口坐标（lng,lat），导航优先使用。
     */
    private String entrLocation;

    /**
     * 首张店铺照片地址。
     */
    private String photo;
}