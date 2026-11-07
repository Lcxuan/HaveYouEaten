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
import com.hye.enums.exception.BusinessException;
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
        RecipeDO recipe = recipeMapper.selectById(dto.getRecipeId());
        if (recipe == null) {
            throw new BusinessException(BusinessErrorCodeConstants.RECIPE_NOT_FOUND);
        }
        EatRecordDO record = new EatRecordDO();
        record.setUserId(LoginContextHolder.getUserId());
        record.setRecipeId(recipe.getId());
        // 名称冗余存储，防菜谱源数据变化影响历史记录展示
        record.setName(recipe.getName());
        record.setSource(StringUtils.hasText(dto.getSource()) ? dto.getSource() : RecordSourceEnum.ROULETTE.getCode());
        record.setEatenAt(LocalDateTime.now());
        record.setRemark(dto.getRemark());
        eatRecordMapper.insert(record);
        return record.getId();
    }

    @Override
    public PageResult<RecordVO> list(PageParam pageParam) {
        PageResult<EatRecordDO> result = eatRecordMapper.selectPageByUser(LoginContextHolder.getUserId(), pageParam);
        return new PageResult<>(
                CollectionUtil.convertList(result.getList(), RecordConvert.INSTANCE::toVO),
                result.getTotal());
    }
}
