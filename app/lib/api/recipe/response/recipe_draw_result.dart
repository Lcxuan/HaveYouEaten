import 'package:have_you_eaten/api/recipe/response/recipe_summary.dart';

/// 抽签结果：候选池大小与抽中的菜谱。
class RecipeDrawResult {
  const RecipeDrawResult({required this.poolSize, required this.recipe});

  factory RecipeDrawResult.fromJson(Map<String, dynamic> json) {
    final recipe = json['recipe'];
    return RecipeDrawResult(
      poolSize: (json['poolSize'] as num?)?.toInt() ?? 0,
      recipe: RecipeSummary.fromJson(
        recipe is Map<String, dynamic> ? recipe : const {},
      ),
    );
  }

  final int poolSize;

  final RecipeSummary recipe;
}
