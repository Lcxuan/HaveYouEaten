package com.hye.service.blacklist;

import com.hye.controller.blacklist.dto.BlacklistCreateDTO;
import com.hye.controller.blacklist.vo.BlacklistVO;

import java.util.List;
import java.util.Set;

public interface BlacklistService {

    /**
     * 新增黑名单
     *
     * @param dto 黑名单参数
     * @return 黑名单 id
     */
    Long add(BlacklistCreateDTO dto);

    /**
     * 移除黑名单。
     *
     * @param scope       粒度：cuisine / poi / recipe
     * @param targetValue 屏蔽值
     */
    void remove(String scope, String targetValue);

    /**
     * 查询当前用户某个粒度下的黑名单。
     *
     * @param scope 粒度：cuisine / poi / recipe
     * @return 黑名单列表
     */
    List<BlacklistVO> list(String scope);

    /**
     * 查询某个粒度下的全部屏蔽值，供抽签与发牌过滤。
     *
     * @param userId 用户 id，未登录时返回空集合
     * @param scope  粒度：cuisine / poi / recipe
     * @return 屏蔽值集合
     */
    Set<String> getBlockedValues(Long userId, String scope);
}
