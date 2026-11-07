/// 菜系字典项。
class Cuisine {
  const Cuisine({
    required this.id,
    required this.name,
    this.mealPeriods = const [],
    this.sort = 0,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    return Cuisine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mealPeriods: (json['mealPeriods'] as List<dynamic>? ?? const [])
          .map((period) => int.tryParse('$period'))
          .whereType<int>()
          .toList(),
      sort: int.tryParse('${json['sort'] ?? 0}') ?? 0,
    );
  }

  final String id;
  final String name;

  /// 适用餐段：1-早餐，2-午餐，3-晚餐，4-夜间；为空表示全餐段可用。
  final List<int> mealPeriods;

  /// 排序值，越小越靠前。
  final int sort;
}
