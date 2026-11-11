package com.hye.service.blacklist.impl;

import com.hye.common.utils.LoginContextHolder;
import com.hye.controller.blacklist.dto.BlacklistCreateDTO;
import com.hye.controller.blacklist.vo.BlacklistVO;
import com.hye.convert.blacklist.BlacklistConvert;
import com.hye.entity.BlacklistDO;
import com.hye.enums.blacklist.BlacklistScopeEnum;
import com.hye.mapper.BlacklistMapper;
import com.hye.service.blacklist.BlacklistService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class BlacklistServiceImpl implements BlacklistService {

    /**
     * 屏蔽值列长度。
     */
    private static final int TARGET_VALUE_MAX_LENGTH = 64;

    /**
     * 备注列长度。
     */
    private static final int REMARK_MAX_LENGTH = 255;

    @Resource
    private BlacklistMapper blacklistMapper;

    @Override
    public Long add(BlacklistCreateDTO dto) {
        BlacklistScopeEnum scope = BlacklistScopeEnum.of(dto.getScope());
        Long userId = LoginContextHolder.getUserId();
        String targetValue = truncate(dto.getTargetValue(), TARGET_VALUE_MAX_LENGTH);

        BlacklistDO existing = blacklistMapper.selectByTarget(userId, scope.getCode(), targetValue);
        if (existing != null) {
            return existing.getId();
        }

        BlacklistDO blacklist = new BlacklistDO();
        blacklist.setUserId(userId);
        blacklist.setScope(scope.getCode());
        blacklist.setTargetValue(targetValue);
        if (dto.getRemark() != null && !dto.getRemark().isBlank()) {
            blacklist.setRemark(truncate(dto.getRemark(), REMARK_MAX_LENGTH));
        }
        blacklistMapper.insert(blacklist);
        return blacklist.getId();
    }

    @Override
    public void remove(String scope, String targetValue) {
        BlacklistScopeEnum scopeEnum = BlacklistScopeEnum.of(scope);
        blacklistMapper.deleteByTarget(LoginContextHolder.getUserId(), scopeEnum.getCode(), targetValue);
    }

    @Override
    public List<BlacklistVO> list(String scope) {
        BlacklistScopeEnum scopeEnum = BlacklistScopeEnum.of(scope);
        List<BlacklistDO> blacklists = blacklistMapper.selectListByScope(
                LoginContextHolder.getUserId(), scopeEnum.getCode());
        return BlacklistConvert.INSTANCE.toVOList(blacklists);
    }

    @Override
    public Set<String> getBlockedValues(Long userId, String scope) {
        if (userId == null) {
            return Set.of();
        }
        BlacklistScopeEnum scopeEnum = BlacklistScopeEnum.of(scope);
        return new HashSet<>(blacklistMapper.selectTargetValues(userId, scopeEnum.getCode()));
    }

    /**
     * 列长度有限，超长时截断避免写入失败。
     */
    private String truncate(String value, int maxLength) {
        return value.length() > maxLength ? value.substring(0, maxLength) : value;
    }
}
