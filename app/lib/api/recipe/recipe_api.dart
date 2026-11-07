import 'package:have_you_eaten/api/recipe/response/recipe_detail.dart';
import 'package:have_you_eaten/api/recipe/response/recipe_draw_result.dart';
import 'package:have_you_eaten/api/request.dart';

/// 菜谱接口：抽签与详情。
class RecipeApi {
  RecipeApi._();

  /// 转盘抽签，筛选条件全部可空（全池随机）。
  static Future<RecipeDrawResult> draw({
    List<int>? cuisineIds,
    List<String>? tastes,
    int? maxCookMinutes,
    int? difficulty,
  }) async {
    final data = await Request.post<Map<String, dynamic>>(
      '/recipe/draw',
      data: {
        if (cuisineIds != null && cuisineIds.isNotEmpty) 'cuisineIds': cuisineIds,
        if (tastes != null && tastes.isNotEmpty) 'tastes': tastes,
        'maxCookMinutes': ?maxCookMinutes,
        'difficulty': ?difficulty,
      },
    );
    return RecipeDrawResult.fromJson(data ?? const {});
  }

  /// 菜谱详情：含完整食材与步骤。
  static Future<RecipeDetail> detail(String id) async {
    final data = await Request.get<Map<String, dynamic>>('/recipe/$id');
    return RecipeDetail.fromJson(data ?? const {});
  }
}
