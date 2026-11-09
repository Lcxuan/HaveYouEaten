package com.hye.service.record.impl;

import com.hye.common.pojo.PageParam;
import com.hye.common.pojo.PageResult;
import com.hye.common.utils.CollectionUtil;
import com.hye.common.utils.LoginContextHolder;
import com.hye.controller.record.dto.RecordCreateDTO;
import com.hye.controller.record.vo.RecordVO;
import com.hye.convert.record.RecordConvert;
import com.hye.entity.EatRecordDO;
import com.hye.entity.RecipeDO;
import com.hye.enums.exception.BusinessErrorCodeConstants;
import com.hye.common.enums.exception.BusinessException;
import com.hye.common.enums.exception.GlobalErrorCodeConstants;
import com.hye.enums.record.RecordSourceEnum;
import com.hye.mapper.EatRecordMapper;
import com.hye.mapper.RecipeMapper;
import com.hye.service.record.RecordService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 吃过记录业务实现。
 */
@Slf4j
@Service
public class RecordServiceImpl implements RecordService {

    @Resource
    private EatRecordMapper eatRecordMapper;

    @Resource
    private RecipeMapper recipeMapper;

    @Override
    public Long create(RecordCreateDTO dto) {
        EatRecordDO record = new EatRecordDO();
        record.setUserId(LoginContextHolder.getUserId());
        record.setEatenAt(LocalDateTime.now());
        record.setRemark(dto.getRemark());

        if (StringUtils.hasText(dto.getPoiId())) {
            // 出去吃：店名冗余存储，店被删/改名也能显示历史记录
            record.setPoiId(dto.getPoiId());
            record.setName(truncate(StringUtils.hasText(dto.getPoiName()) ? dto.getPoiName() : "堂食餐厅"));
            record.setSource(StringUtils.hasText(dto.getSource())
                    ? dto.getSource()
                    : RecordSourceEnum.POI.getCode());
        } else {
            if (dto.getRecipeId() == null) {
                throw new BusinessException(GlobalErrorCodeConstants.BAD_REQUEST, "菜谱 id 与门店 id 不能同时为空");
            }
            RecipeDO recipe = recipeMapper.selectById(dto.getRecipeId());
            if (recipe == null) {
                throw new BusinessException(BusinessErrorCodeConstants.RECIPE_NOT_FOUND);
            }
            record.setRecipeId(recipe.getId());
            record.setName(truncate(recipe.getName()));
            record.setSource(StringUtils.hasText(dto.getSource())
                    ? dto.getSource()
                    : RecordSourceEnum.ROULETTE.getCode());
        }

        eatRecordMapper.insert(record);
        return record.getId();
    }

    /**
     * 名称列长度为 64，超长时截断避免写入失败。
     */
    private String truncate(String name) {
        return name.length() > 64 ? name.substring(0, 64) : name;
    }

    @Override
    public PageResult<RecordVO> list(PageParam pageParam) {
        PageResult<EatRecordDO> result = eatRecordMapper.selectPageByUser(LoginContextHolder.getUserId(), pageParam);
        return new PageResult<>(
                CollectionUtil.convertList(result.getList(), RecordConvert.INSTANCE::toVO),
                result.getTotal());
    }
}
