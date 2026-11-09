package com.hye.controller.record.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "记一笔参数")
public class RecordCreateDTO {

    @Schema(description = "菜谱 id（在家吃时填写）")
    private Long recipeId;

    @Schema(description = "高德 POI id（出去吃时填写）")
    private String poiId;

    @Schema(description = "店名（出去吃时填写，冗余存储）")
    private String poiName;

    @Schema(description = "来源：roulette-抽签，poi-堂食，manual-手动，ai_recommend-AI 推荐，不传按场景默认")
    private String source;

    @Schema(description = "备注")
    private String remark;
}
