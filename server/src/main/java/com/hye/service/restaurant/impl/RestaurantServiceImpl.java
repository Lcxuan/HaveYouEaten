package com.hye.service.restaurant.impl;

import com.hye.framework.amap.api.AmapApi;
import com.hye.framework.amap.api.dto.AmapApiAroundDTO;
import com.hye.framework.amap.api.vo.AmapApiPoiVO;
import com.hye.framework.amap.enums.AmapPageSizeEnum;
import com.hye.common.utils.CollectionUtil;
import com.hye.common.utils.DateUtils;
import com.hye.common.utils.LoginContextHolder;
import com.hye.controller.restaurant.dto.RestaurantDeckDTO;
import com.hye.controller.restaurant.vo.DineCuisineVO;
import com.hye.controller.restaurant.vo.RestaurantCuisineVO;
import com.hye.controller.restaurant.vo.RestaurantDeckVO;
import com.hye.controller.restaurant.vo.RestaurantVO;
import com.hye.convert.restaurant.DineCuisineConvert;
import com.hye.convert.restaurant.RestaurantConvert;
import com.hye.entity.DineCuisineDO;
import com.hye.entity.EatRecordDO;
import com.hye.enums.exception.BusinessErrorCodeConstants;
import com.hye.enums.restaurant.RestaurantDrawRuleEnum;
import com.hye.common.enums.exception.BusinessException;
import com.hye.mapper.EatRecordMapper;
import com.hye.redis.restaurant.RestaurantRedis;
import com.hye.service.restaurant.DineCuisineService;
import com.hye.service.restaurant.RestaurantService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 出去吃业务实现：抽菜系、拉附近餐厅、过滤排序后发牌。
 */
@Service
public class RestaurantServiceImpl implements RestaurantService {

    /**
     * 餐饮服务全集分类码。
     */
    private static final String TYPES_RESTAURANT = "050000";

    @Resource
    private RestaurantRedis restaurantRedis;

    @Resource
    private AmapApi amapApi;

    @Resource
    private DineCuisineService dineCuisineService;

    @Resource
    private EatRecordMapper eatRecordMapper;

    @Override
    public List<DineCuisineVO> getDineCuisines() {
        return DineCuisineConvert.INSTANCE.toVOList(dineCuisineService.getEnabledList());
    }

    @Override
    public RestaurantDeckVO deck(RestaurantDeckDTO dto) {
        // 1. 随机抽一个菜系
        DineCuisineDO cuisine = pickCuisine(dto);
        // 2. 按菜系获取附近餐厅：大类码 + 餐饮全集 + 菜系关键词
        String types = StringUtils.hasText(cuisine.getBigType())
                ? cuisine.getBigType() + "|" + TYPES_RESTAURANT
                : TYPES_RESTAURANT;
        List<AmapApiPoiVO> pois = getNearbyRestaurants(types, cuisine.getName(), dto.getLng(), dto.getLat(), dto.getRadius());

        // 3. 按人均预算过滤；未设上限或店铺未提供人均时保留
        Integer maxCost = dto.getMaxCost();
        List<AmapApiPoiVO> options = pois.stream()
                .filter(poi -> maxCost == null || poi.getCost() == null || poi.getCost() <= maxCost)
                .toList();
        if (options.isEmpty()) {
            throw new BusinessException(BusinessErrorCodeConstants.RESTAURANT_POOL_EMPTY);
        }

        // 4. 随机打乱，并把最近吃过的店稳定排到队尾，避免每次都是距离最近的那几家
        List<AmapApiPoiVO> sorted = new ArrayList<>(options);
        sortByRecommendation(sorted);

        // 5. 组装发牌结果：菜系 + 候选池大小 + 排好序的卡片
        return RestaurantDeckVO.builder()
                .cuisine(RestaurantCuisineVO.builder()
                        .id(cuisine.getId())
                        .name(cuisine.getName())
                        .build())
                .poolSize(sorted.size())
                .options(RestaurantConvert.INSTANCE.toVOList(sorted))
                .build();
    }

    @Override
    public RestaurantVO detail(String poiId) {
        if (!StringUtils.hasText(poiId)) {
            throw new BusinessException(BusinessErrorCodeConstants.RESTAURANT_NOT_FOUND);
        }
        AmapApiPoiVO poi = amapApi.detail(poiId);
        if (poi == null) {
            throw new BusinessException(BusinessErrorCodeConstants.RESTAURANT_NOT_FOUND);
        }
        return RestaurantConvert.INSTANCE.toVO(poi);
    }

    /**
     * 抽取一个菜系
     * 1、优先在用户选择的池子里抽
     * 2、未选则从全部启用菜系里抽，再排除刚抽过的
     */
    private DineCuisineDO pickCuisine(RestaurantDeckDTO dto) {
        // 1. 取全部启用菜系（该查询带 5 分钟缓存，不会每次发牌都打库）
        List<DineCuisineDO> enabled = dineCuisineService.getEnabledList();
        if (CollectionUtils.isEmpty(enabled)) {
            throw new BusinessException(BusinessErrorCodeConstants.RESTAURANT_CUISINE_EMPTY);
        }

        // 2. 用户在筛选面板选了菜系时，只在所选范围内抽；没选则用全部启用菜系
        Set<Long> selected = dto.getCuisineIds() == null
                ? Set.of()
                : new HashSet<>(dto.getCuisineIds());
        List<DineCuisineDO> candidates = selected.isEmpty()
                ? enabled
                : enabled.stream().filter(cuisine -> selected.contains(cuisine.getId())).toList();
        if (candidates.isEmpty()) {
            throw new BusinessException(BusinessErrorCodeConstants.RESTAURANT_CUISINE_EMPTY);
        }

        // 3. 再排除「换菜系」时刚抽过的，避免连续两次抽到同一个
        Set<Long> excluded = dto.getExcludeCuisineIds() == null
                ? Set.of()
                : new HashSet<>(dto.getExcludeCuisineIds());
        List<DineCuisineDO> filtered = candidates.stream()
                .filter(cuisine -> !excluded.contains(cuisine.getId()))
                .toList();
        // 4. 若排除后没有候选，清空排除重来一次，避免「换菜系」把自己卡死
        if (filtered.isEmpty()) {
            filtered = candidates;
        }
        // 5. 在最终候选里随机抽一个
        return filtered.get(ThreadLocalRandom.current().nextInt(filtered.size()));
    }

    /**
     * 拉取附近餐厅 POI
     *
     * @param types    高德分类码，多个用 | 分隔
     * @param keywords 菜系关键词，与分类码一起限定召回范围
     * @param lng      经度（GCJ-02）
     * @param lat      纬度（GCJ-02）
     * @param radius   搜索半径（米）
     * @return 去重后的附近餐厅列表，最多两页
     */
    private List<AmapApiPoiVO> getNearbyRestaurants(String types, String keywords, double lng, double lat, int radius) {
        // 1. 先读 Redis 缓存，命中直接返回，避免重复调用高德
        List<AmapApiPoiVO> cached = restaurantRedis.getPois(types, keywords, lng, lat, radius);
        if (cached != null) {
            return cached;
        }

        // 2. 未命中则翻页请求高德，按 POI id 去重合并
        Map<String, AmapApiPoiVO> merged = new LinkedHashMap<>();
        for (int page = 1; page <= AmapPageSizeEnum.MAX_PAGES.getValue(); page++) {
            List<AmapApiPoiVO> pois = amapApi.around(AmapApiAroundDTO.builder()
                    .types(types)
                    .keywords(keywords)
                    .lng(lng)
                    .lat(lat)
                    .radius(radius)
                    .pageNum(page)
                    .build());
            for (AmapApiPoiVO poi : pois) {
                merged.putIfAbsent(poi.getPoiId(), poi);
            }
            // 3. 本页不满一页说明已经到底，不必再请求下一页
            if (pois.size() < AmapPageSizeEnum.DEFAULT.getValue()) {
                break;
            }
        }

        // 4. 回写 Redis 缓存（5 分钟过期）后返回
        List<AmapApiPoiVO> result = new ArrayList<>(merged.values());
        restaurantRedis.setPois(types, keywords, lng, lat, radius, result);
        return result;
    }

    /**
     * 随机打乱，并把最近吃过的店排到队尾。
     *
     * @param pois 待排序的餐厅列表，原地修改
     */
    private void sortByRecommendation(List<AmapApiPoiVO> pois) {
        // 查出最近 N 天内吃过的 POI id；未登录时查不到记录，相当于不做降权
        Long userId = LoginContextHolder.getUserId();
        List<EatRecordDO> recentRecords = eatRecordMapper.selectRecentPoiRecords(
                userId, DateUtils.nowMinusDays(RestaurantDrawRuleEnum.RECENT_DAYS.getDays()));
        Set<String> recent = CollectionUtil.convertSet(recentRecords, EatRecordDO::getPoiId);
        Collections.shuffle(pois);
        // List.sort 是稳定排序，会保留上一步的随机顺序，只把吃过的挪到末尾
        pois.sort(Comparator.comparing((AmapApiPoiVO poi) -> recent.contains(poi.getPoiId())));
    }
}
