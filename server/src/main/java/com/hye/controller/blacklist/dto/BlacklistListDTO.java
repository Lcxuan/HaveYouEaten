package com.hye.controller.blacklist.dto;

import com.hye.enums.blacklist.BlacklistScopeEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
@Schema(description = "黑名单列表查询参数")
public class BlacklistListDTO {

    @Schema(description = "粒度：cuisine-菜系，poi-餐厅，recipe-菜谱")
    @NotBlank(message = "黑名单类型不能为空")
    @Pattern(regexp = BlacklistScopeEnum.CODES_REGEXP,
            message = "黑名单类型仅支持 cuisine、poi 或 recipe")
    private String scope;
}
