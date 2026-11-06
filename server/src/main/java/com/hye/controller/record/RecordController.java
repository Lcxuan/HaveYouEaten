package com.hye.controller.record;

import com.hye.common.Result;
import com.hye.common.pojo.PageResult;
import com.hye.controller.record.dto.RecordCreateDTO;
import com.hye.controller.record.dto.RecordListDTO;
import com.hye.controller.record.vo.RecordVO;
import com.hye.service.record.RecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 吃过记录接口。
 */
@Tag(name = "吃过记录")
@RestController
@RequestMapping("/api/record")
public class RecordController {

    @Resource
    private RecordService recordService;

    /**
     * 记一笔。
     *
     * @param dto 记录参数
     * @return 记录 id
     */
    @PostMapping
    @Operation(summary = "记一笔")
    public Result<Long> create(@Valid @RequestBody RecordCreateDTO dto) {
        return Result.success(recordService.create(dto));
    }

    /**
     * 分页查询当前用户最近 N 天的吃饭记录。
     *
     * @param dto 查询参数：天数、页码、每页条数
     * @return 分页记录，按吃饭时间倒序
     */
    @GetMapping("/list")
    @Operation(summary = "吃过记录列表（分页）")
    public Result<PageResult<RecordVO>> list(@ParameterObject RecordListDTO dto) {
        return Result.success(recordService.listRecent(dto));
    }
}
