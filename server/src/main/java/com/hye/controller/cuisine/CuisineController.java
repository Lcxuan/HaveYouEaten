package com.hye.controller.cuisine;

import com.hye.common.Result;
import com.hye.controller.cuisine.vo.CuisineVO;
import com.hye.service.cuisine.CuisineService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 菜系接口：字典查询。
 */
@Tag(name = "菜系")
@RestController
@RequestMapping("/api/cuisine")
public class CuisineController {

    @Resource
    private CuisineService cuisineService;

    /**
     * 查询全部启用的菜系，按排序值升序，供转盘与筛选使用。
     *
     * @return 菜系列表
     */
    @GetMapping("/list")
    @Operation(summary = "菜系列表")
    public Result<List<CuisineVO>> list() {
        return Result.success(cuisineService.getEnabledList());
    }
}
