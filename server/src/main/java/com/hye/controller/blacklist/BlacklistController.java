package com.hye.controller.blacklist;

import com.hye.common.Result;
import com.hye.controller.blacklist.dto.BlacklistCreateDTO;
import com.hye.controller.blacklist.dto.BlacklistListDTO;
import com.hye.controller.blacklist.dto.BlacklistRemoveDTO;
import com.hye.controller.blacklist.vo.BlacklistVO;
import com.hye.service.blacklist.BlacklistService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "黑名单")
@RestController
@RequestMapping("/api/blacklist")
public class BlacklistController {

    @Resource
    private BlacklistService blacklistService;

    /**
     * 新增黑名单。
     *
     * @param dto 黑名单参数
     * @return 黑名单 id
     */
    @PostMapping
    @Operation(summary = "新增黑名单")
    public Result<Long> add(@Valid @RequestBody BlacklistCreateDTO dto) {
        return Result.success(blacklistService.add(dto));
    }

    /**
     * 移除黑名单。
     *
     * @param dto 移除参数
     * @return 空结果
     */
    @DeleteMapping
    @Operation(summary = "移除黑名单")
    public Result<Void> remove(@Valid @ParameterObject BlacklistRemoveDTO dto) {
        blacklistService.remove(dto.getScope(), dto.getTargetValue());
        return Result.success();
    }

    /**
     * 查询当前用户某个粒度下的黑名单。
     *
     * @param dto 查询参数
     * @return 黑名单列表
     */
    @GetMapping("/list")
    @Operation(summary = "黑名单列表")
    public Result<List<BlacklistVO>> list(@Valid @ParameterObject BlacklistListDTO dto) {
        return Result.success(blacklistService.list(dto.getScope()));
    }
}
