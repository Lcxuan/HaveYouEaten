package com.hye.framework.amap.service.bo;

import cn.hutool.core.annotation.Alias;
import lombok.Data;

import java.util.List;

/**
 * 高德地点接口（周边搜索 / 详情）响应包装。
 */
@Data
public class AmapPlaceBO {

    /**
     * 返回状态，1-成功。
     */
    private String status;

    /**
     * 返回状态说明。
     */
    private String info;

    /**
     * 状态码。
     */
    private String infocode;

    /**
     * POI 明细列表。
     */
    private List<AmapPoi> pois;

    /**
     * 高德 POI 明细（原始响应结构）。
     *
     */
    @Data
    public static class AmapPoi {

        /**
         * 高德 POI id。
         */
        private String id;

        /**
         * 门店名称。
         */
        private String name;

        /**
         * 门店地址。
         */
        private String address;

        /**
         * 高德分类码。
         */
        private String typecode;

        /**
         * 联系电话。
         */
        private String tel;

        /**
         * 距查询点距离（米）。
         */
        private String distance;

        /**
         * 坐标，格式 lng,lat。
         */
        private String location;

        /**
         * 营业信息。
         */
        private Business business;

        /**
         * 导航信息。
         */
        private Navi navi;

        /**
         * 照片列表。
         */
        private List<Photo> photos;

        /**
         * 营业信息。
         */
        @Data
        public static class Business {

            /**
             * 评分。
             */
            private String rating;

            /**
             * 人均消费（元）。
             */
            private String cost;

            /**
             * 今日营业时间，如 10:00-22:00。
             */
            @Alias("opentime_today")
            private String opentimeToday;

            /**
             * 标签。
             */
            private Object tag;

            /**
             * 关键标签。
             */
            private Object keytag;
        }

        /**
         * 导航信息。
         */
        @Data
        public static class Navi {

            /**
             * 入口坐标（lng,lat）。
             */
            @Alias("entr_location")
            private String entrLocation;
        }

        /**
         * 照片。
         */
        @Data
        public static class Photo {

            /**
             * 照片地址。
             */
            private String url;
        }
    }
}