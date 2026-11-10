import 'package:have_you_eaten/api/request.dart';
import 'package:have_you_eaten/api/restaurant/response/dine_cuisine.dart';
import 'package:have_you_eaten/api/restaurant/response/restaurant.dart';
import 'package:have_you_eaten/api/restaurant/response/restaurant_deck.dart';

/// 出去吃接口：菜系字典、发牌与餐厅详情。
class RestaurantApi {
  RestaurantApi._();

  /// 查询全部启用的出去吃菜系，供筛选面板与抽签使用。
  static Future<List<DineCuisine>> cuisines() async {
    final data = await Request.get<List<dynamic>>('/restaurant/cuisines');
    return (data ?? const [])
        .map((item) => DineCuisine.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 发一叠餐厅卡：服务端先抽菜系，再返回该菜系附近的店。
  static Future<RestaurantDeck> deck({
    required double lng,
    required double lat,
    int radius = 3000,
    List<int>? cuisineIds,
    List<int>? excludeCuisineIds,
    int? maxCost,
  }) async {
    final data = await Request.post<Map<String, dynamic>>(
      '/restaurant/deck',
      data: {
        'lng': lng,
        'lat': lat,
        'radius': radius,
        if (cuisineIds != null && cuisineIds.isNotEmpty)
          'cuisineIds': cuisineIds,
        if (excludeCuisineIds != null && excludeCuisineIds.isNotEmpty)
          'excludeCuisineIds': excludeCuisineIds,
        'maxCost': ?maxCost,
      },
    );
    return RestaurantDeck.fromJson(data ?? const {});
  }

  /// 餐厅详情。
  static Future<Restaurant> detail(String poiId) async {
    final data = await Request.get<Map<String, dynamic>>(
      '/restaurant/$poiId',
    );
    return Restaurant.fromJson(data ?? const {});
  }
}
