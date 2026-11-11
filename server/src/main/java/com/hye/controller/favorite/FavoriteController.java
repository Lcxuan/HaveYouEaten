package com.hye.controller.favorite;

import com.hye.common.Result;
import com.hye.common.pojo.PageResult;
import com.hye.controller.favorite.dto.FavoriteCreateDTO;
import com.hye.controller.favorite.dto.FavoriteListDTO;
import com.hye.controller.favorite.dto.FavoriteRemoveDTO;
import com.hye.controller.favorite.dto.FavoriteStatusDTO;
import com.hye.controller.favorite.vo.FavoriteVO;
import com.hye.service.favorite.FavoriteService;
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

@Tag(name = "收藏")
@RestController
@RequestMapping("/api/favorite")
public class FavoriteController {

    @Resource
    private FavoriteService favoriteService;

    /**
     * 新增收藏。
     *
     * @param dto 收藏参数
     * @return 收藏 id
     */
    @PostMapping
    @Operation(summary = "新增收藏")
    public Result<Long> add(@Valid @RequestBody FavoriteCreateDTO dto) {
        return Result.success(favoriteService.add(dto));
    }

    /**
     * 取消收藏。
     *
     * @param dto 取消收藏参数
     * @return 空结果
     */
    @DeleteMapping
    @Operation(summary = "取消收藏")
    public Result<Void> remove(@Valid @ParameterObject FavoriteRemoveDTO dto) {
        favoriteService.remove(dto.getTargetType(), dto.getTargetId());
        return Result.success();
    }

    /**
     * 分页查询当前用户某一类型的收藏。
     *
     * @param dto 列表查询参数
     * @return 分页收藏
     */
    @GetMapping("/list")
    @Operation(summary = "收藏列表（分页）")
    public Result<PageResult<FavoriteVO>> list(@Valid @ParameterObject FavoriteListDTO dto) {
        return Result.success(favoriteService.list(dto.getTargetType(), dto));
    }

    /**
     * 查询当前用户是否已收藏某个目标。
     *
     * @param dto 状态查询参数
     * @return 是否已收藏
     */
    @GetMapping("/status")
    @Operation(summary = "收藏状态")
    public Result<Boolean> status(@Valid @ParameterObject FavoriteStatusDTO dto) {
        return Result.success(favoriteService.status(dto.getTargetType(), dto.getTargetId()));
    }
}
