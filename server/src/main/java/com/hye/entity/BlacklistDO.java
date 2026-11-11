package com.hye.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.hye.common.entity.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("blacklist")
public class BlacklistDO extends BaseDO {

    /**
     * 用户 id。
     */
    private Long userId;

    /**
     * 粒度：cuisine-菜系，poi-餐厅，recipe-菜谱。
     */
    private String scope;

    /**
     * 屏蔽值（菜系名 / POI id / 菜谱 id）。
     */
    private String targetValue;

    /**
     * 拉黑原因备注。
     */
    private String remark;
}
