import 'package:have_you_eaten/api/restaurant/response/restaurant.dart';

/// 一条收藏记录。
class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.name,
    required this.createTime,
    this.restaurant,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final extra = json['extra'];
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createTime:
          DateTime.tryParse(json['createTime']?.toString() ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      restaurant: extra is Map<String, dynamic>
          ? Restaurant.fromJson(extra)
          : null,
    );
  }

  final String id;

  /// 类型：recipe-菜谱，restaurant-餐厅。
  final String targetType;

  /// 菜谱 id 或高德 POI id。
  final String targetId;

  /// 菜名 / 店名。
  final String name;

  final DateTime createTime;

  /// 餐厅快照；旧收藏或非餐厅类型为 null。
  final Restaurant? restaurant;

  bool get isRecipe => targetType == 'recipe';
}
