package com.hye.controller.record.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 吃过记录。
 */
@Data
@Schema(description = "吃过记录")
public class RecordVO {

    @Schema(description = "记录 id")
    private Long id;

    @Schema(description = "菜谱 id（在家吃时有值）")
    private Long recipeId;

    @Schema(description = "名称（菜名/店名）")
    private String name;

    @Schema(description = "来源：roulette-抽签，manual-手动，ai_recommend-AI 推荐")
    private String source;

    @Schema(description = "吃饭时间")
    private LocalDateTime eatenAt;

    @Schema(description = "备注")
    private String remark;
}
