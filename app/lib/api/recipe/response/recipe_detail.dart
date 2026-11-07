import 'package:have_you_eaten/api/recipe/response/recipe_summary.dart';

/// 菜谱详情：摘要信息 + 完整食材与做法步骤。
class RecipeDetail {
  const RecipeDetail({
    required this.summary,
    required this.ingredients,
    required this.steps,
  });

  final RecipeSummary summary;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      summary: RecipeSummary.fromJson(json),
      ingredients: [
        for (final item in (json['ingredients'] as List? ?? const []))
          RecipeIngredient.fromJson(item as Map<String, dynamic>),
      ],
      steps: [
        for (final item in (json['steps'] as List? ?? const []))
          RecipeStep.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

/// 食材项：名称 + 用量。
class RecipeIngredient {
  const RecipeIngredient({required this.name, required this.amount});

  final String name;
  final String amount;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
    );
  }
}

/// 做法步骤项：序号 + 描述。
class RecipeStep {
  const RecipeStep({required this.order, required this.text});

  final int order;
  final String text;

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      order: json['order'] as int? ?? 0,
      text: json['text'] as String? ?? '',
    );
  }
}
