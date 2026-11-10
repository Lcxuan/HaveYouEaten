/// 出去吃菜系列表项（与「在家吃」菜系相互独立）。
class DineCuisine {
  const DineCuisine({
    required this.id,
    required this.name,
    this.sort = 0,
  });

  factory DineCuisine.fromJson(Map<String, dynamic> json) {
    return DineCuisine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sort: int.tryParse('${json['sort'] ?? 0}') ?? 0,
    );
  }

  final String id;
  final String name;

  /// 排序值，越小越靠前。
  final int sort;
}