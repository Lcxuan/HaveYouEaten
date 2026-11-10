import 'package:have_you_eaten/api/restaurant/response/restaurant.dart';

/// 出去吃：一叠已排好序的餐厅卡。
class RestaurantDeck {
  const RestaurantDeck({
    required this.cuisineId,
    required this.cuisineName,
    required this.poolSize,
    required this.options,
  });

  factory RestaurantDeck.fromJson(Map<String, dynamic> json) {
    final cuisine = json['cuisine'];
    final list = json['options'] as List<dynamic>? ?? const [];
    return RestaurantDeck(
      cuisineId: cuisine is Map ? cuisine['id']?.toString() ?? '' : '',
      cuisineName: cuisine is Map ? cuisine['name']?.toString() ?? '' : '',
      poolSize: int.tryParse('${json['poolSize'] ?? 0}') ?? 0,
      options: list
          .whereType<Map<String, dynamic>>()
          .map(Restaurant.fromJson)
          .toList(),
    );
  }

  final String cuisineId;
  final String cuisineName;

  /// 过滤后的候选店数。
  final int poolSize;

  /// 按翻牌顺序排列的卡片。
  final List<Restaurant> options;

  bool get isEmpty => options.isEmpty;
}
