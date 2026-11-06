package com.hye.controller.record.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 记一笔参数。
 */
@Data
@Schema(description = "记一笔参数")
public class RecordCreateDTO {

    @NotNull(message = "菜谱 id 不能为空")
    @Schema(description = "菜谱 id（在家吃时填写）")
    private Long recipeId;

    @Schema(description = "来源：roulette-抽签，manual-手动，ai_recommend-AI 推荐，不传默认抽签")
    private String source;

    @Schema(description = "备注")
    private String remark;
}
