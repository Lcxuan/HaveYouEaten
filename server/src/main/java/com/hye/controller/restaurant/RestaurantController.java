package com.hye.controller.restaurant;

import com.hye.common.Result;
import com.hye.controller.restaurant.dto.RestaurantDeckDTO;
import com.hye.controller.restaurant.vo.DineCuisineVO;
import com.hye.controller.restaurant.vo.RestaurantDeckVO;
import com.hye.controller.restaurant.vo.RestaurantVO;
import com.hye.service.restaurant.RestaurantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "餐厅")
@RestController
@RequestMapping("/api/restaurant")
public class RestaurantController {

    @Resource
    private RestaurantService restaurantService;

    /**
     * 查询全部启用的出去吃菜系
     *
     * @return 菜系列表
     */
    @GetMapping("/cuisines")
    @Operation(summary = "出去吃菜系列表")
    public Result<List<DineCuisineVO>> cuisines() {
        return Result.success(restaurantService.getDineCuisines());
    }

    /**
     * 发牌：先抽菜系，再返回该菜系附近已排好序的餐厅。
     *
     * @param dto 位置与筛选条件
     * @return 一叠餐厅卡
     */
    @PostMapping("/deck")
    @Operation(summary = "出去吃发牌")
    public Result<RestaurantDeckVO> deck(@Valid @RequestBody RestaurantDeckDTO dto) {
        return Result.success(restaurantService.deck(dto));
    }

    /**
     * 餐厅详情。
     *
     * @param poiId 高德 POI id
     * @return 餐厅卡片
     */
    @GetMapping("/{poiId}")
    @Operation(summary = "餐厅详情")
    public Result<RestaurantVO> detail(@PathVariable String poiId) {
        return Result.success(restaurantService.detail(poiId));
    }
}
