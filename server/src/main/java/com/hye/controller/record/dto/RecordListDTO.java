package com.hye.controller.record.dto;

import com.hye.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 吃过记录分页查询参数。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(description = "吃过记录分页查询参数")
public class RecordListDTO extends PageParam {

    /**
     * 查询最近天数，默认 7。
     */
    @Schema(description = "最近天数，默认 7，上限 30")
    private Integer days = 7;
}
