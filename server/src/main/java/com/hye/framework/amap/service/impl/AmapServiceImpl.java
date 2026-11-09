package com.hye.framework.amap.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.util.NumberUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.hye.common.utils.HttpUtils;
import com.hye.config.AmapProperties;
import com.hye.framework.amap.api.dto.AmapApiAroundDTO;
import com.hye.framework.amap.api.vo.AmapApiPoiVO;
import com.hye.framework.amap.enums.AmapPageSizeEnum;
import com.hye.framework.amap.exception.AmapErrorCodeConstants;
import com.hye.framework.amap.exception.AmapException;
import com.hye.framework.amap.service.AmapService;
import com.hye.framework.amap.service.bo.AmapPlaceBO;
import com.hye.framework.amap.service.bo.AmapPlaceBO.AmapPoi;
import com.hye.framework.amap.service.dto.AmapAroundQueryDTO;
import com.hye.framework.amap.service.dto.AmapDetailQueryDTO;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class AmapServiceImpl implements AmapService {

    /**
     * 餐饮服务分类码。
     */
    private static final String TYPES_RESTAURANT = "050000";

    @Resource
    private AmapProperties properties;

    @Override
    public List<AmapApiPoiVO> around(AmapApiAroundDTO dto) {
        checkKey();

        AmapAroundQueryDTO query = AmapAroundQueryDTO.builder()
                .location(dto.getLng() + "," + dto.getLat())
                .radius(String.valueOf(dto.getRadius()))
                .types(StringUtils.hasText(dto.getTypes()) ? dto.getTypes() : TYPES_RESTAURANT)
                .keywords(dto.getKeywords())
                .sortrule("distance")
                .pageSize(String.valueOf(AmapPageSizeEnum.DEFAULT.getValue()))
                .pageNum(String.valueOf(dto.getPageNum()))
                .showFields("business,navi,photos")
                .key(properties.getKey())
                .build();

        AmapPlaceBO response = request("/v5/place/around", BeanUtil.beanToMap(query, true, true));
        List<AmapApiPoiVO> result = new ArrayList<>();
        if (response.getPois() != null) {
            for (AmapPoi poiDto : response.getPois()) {
                AmapApiPoiVO poi = convert(poiDto);
                if (poi != null) {
                    result.add(poi);
                }
            }
        }
        return result;
    }

    @Override
    public AmapApiPoiVO detail(String poiId) {
        checkKey();

        AmapDetailQueryDTO query = AmapDetailQueryDTO.builder()
                .id(poiId)
                .showFields("business,photos,navi")
                .key(properties.getKey())
                .build();

        AmapPlaceBO response = request("/v5/place/detail", BeanUtil.beanToMap(query, true, true));
        if (response.getPois() == null || response.getPois().isEmpty()) {
            return null;
        }
        return convert(response.getPois().get(0));
    }

    /**
     * 未配置 key 时，提示功能未配置。
     */
    private void checkKey() {
        if (!StringUtils.hasText(properties.getKey())) {
            throw new AmapException(AmapErrorCodeConstants.UNAVAILABLE);
        }
    }

    /**
     * 发起 GET 请求并校验高德返回状态，失败重试一次。
     */
    private AmapPlaceBO request(String path, Map<String, Object> params) {
        RuntimeException lastError = null;
        for (int attempt = 0; attempt < 2; attempt++) {
            try {
                String body = HttpUtils.get(properties.getBaseUrl() + path, params, properties.getTimeout());
                AmapPlaceBO response = JSONUtil.toBean(body, AmapPlaceBO.class);
                if (!StrUtil.equals("1", response.getStatus())) {
                    log.warn("高德接口返回失败：path={} infocode={} info={}", path, response.getInfocode(), response.getInfo());
                    throw new AmapException(AmapErrorCodeConstants.QUERY_FAILED);
                }
                return response;
            } catch (AmapException exception) {
                throw exception;
            } catch (Exception exception) {
                lastError = new AmapException(AmapErrorCodeConstants.QUERY_FAILED);
                log.warn("高德接口请求异常（第 {} 次）：{}", attempt + 1, exception.getMessage());
            }
        }
        throw lastError == null
                ? new AmapException(AmapErrorCodeConstants.QUERY_FAILED)
                : lastError;
    }

    /**
     * 把高德原始 POI 明细转成业务实体
     */
    private AmapApiPoiVO convert(AmapPoi dto) {
        if (dto == null || !StringUtils.hasText(dto.getId()) || !StringUtils.hasText(dto.getName())) {
            return null;
        }

        AmapApiPoiVO poi = new AmapApiPoiVO();
        poi.setPoiId(dto.getId());
        poi.setName(dto.getName());
        poi.setAddress(dto.getAddress());
        poi.setTypecode(dto.getTypecode());
        poi.setTel(dto.getTel());
        poi.setDistance(NumberUtil.parseInt(dto.getDistance()));

        String location = dto.getLocation();
        if (location != null && location.contains(",")) {
            String[] parts = location.split(",");
            poi.setLng(NumberUtil.parseDouble(parts[0]));
            poi.setLat(NumberUtil.parseDouble(parts[1]));
        }

        AmapPoi.Business business = dto.getBusiness();
        if (business != null) {
            poi.setRating(NumberUtil.parseDouble(business.getRating()));
            poi.setCost(NumberUtil.parseDouble(business.getCost()));
            poi.setOpenTime(business.getOpentimeToday());
            poi.setTags(splitTags(business.getTag(), business.getKeytag()));
        }

        AmapPoi.Navi navi = dto.getNavi();
        if (navi != null) {
            poi.setEntrLocation(navi.getEntrLocation());
        }

        List<AmapPoi.Photo> photos = dto.getPhotos();
        if (photos != null && !photos.isEmpty() && StringUtils.hasText(photos.get(0).getUrl())) {
            poi.setPhoto(photos.get(0).getUrl());
        }
        return poi;
    }

    /**
     * 标签可能分布在 tag 与 keytag 两个字段，去重合并。
     * 高德对 tag/keytag 可能返回逗号分隔字符串，也可能是字符串数组。
     */
    private List<String> splitTags(Object tag, Object keytag) {
        List<String> tags = new ArrayList<>();
        addTag(tags, tag);
        addTag(tags, keytag);
        return tags;
    }

    /**
     * 把一个标签源（可能是字符串数组，也可能是逗号分隔字符串）解析后并入标签集合。
     */
    private void addTag(List<String> tags, Object source) {
        if (source instanceof Iterable<?> iterable) {
            for (Object item : iterable) {
                addOne(tags, item);
            }
            return;
        }
        if (source != null) {
            addOne(tags, String.valueOf(source));
        }
    }

    /**
     * 把单个值切分、去空白、去重后并入标签集合，忽略空值。
     */
    private void addOne(List<String> tags, Object value) {
        if (value == null) {
            return;
        }
        for (String item : String.valueOf(value).split(",")) {
            String trimmed = item.trim();
            if (!trimmed.isEmpty() && !tags.contains(trimmed)) {
                tags.add(trimmed);
            }
        }
    }
}