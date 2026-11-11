package com.hye.controller.blacklist.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Schema(description = "黑名单记录")
public class BlacklistVO {

    @Schema(description = "黑名单 id")
    private Long id;

    @Schema(description = "粒度：cuisine-菜系，poi-餐厅，recipe-菜谱")
    private String scope;

    @Schema(description = "屏蔽值（菜系名 / POI id / 菜谱 id）")
    private String targetValue;

    @Schema(description = "拉黑原因备注")
    private String remark;

    @Schema(description = "创建时间")
    private LocalDateTime createTime;
}
