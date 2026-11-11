import 'package:have_you_eaten/api/favorite/response/favorite_item.dart';
import 'package:have_you_eaten/api/favorite/response/favorite_page.dart';
import 'package:have_you_eaten/api/request.dart';

/// 收藏接口。
class FavoriteApi {
  FavoriteApi._();

  /// 新增收藏；服务端幂等，重复收藏不会报错。
  static Future<void> add({
    required String targetType,
    required String targetId,
    required String name,
    Map<String, dynamic>? extra,
  }) async {
    final data = <String, dynamic>{
      'targetType': targetType,
      'targetId': targetId,
      'name': name,
    };
    if (extra != null && extra.isNotEmpty) {
      data['extra'] = extra;
    }
    await Request.post<void>('/favorite', data: data);
  }

  /// 取消收藏。
  static Future<void> remove({
    required String targetType,
    required String targetId,
  }) async {
    await Request.delete<void>(
      '/favorite',
      queryParameters: {'targetType': targetType, 'targetId': targetId},
    );
  }

  /// 分页查询某一类型的收藏。
  static Future<FavoritePage> list({
    required String targetType,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    final data = await Request.get<Map<String, dynamic>>(
      '/favorite/list',
      queryParameters: {
        'targetType': targetType,
        'pageNo': pageNo,
        'pageSize': pageSize,
      },
    );
    final list = data?['list'] as List<dynamic>? ?? const [];
    final items = list
        .whereType<Map<String, dynamic>>()
        .map(FavoriteItem.fromJson)
        .toList();
    final total = int.tryParse('${data?['total'] ?? ''}') ?? items.length;
    return FavoritePage(items: items, total: total);
  }

  /// 查询当前用户是否已收藏某个目标。
  static Future<bool> status({
    required String targetType,
    required String targetId,
  }) async {
    final data = await Request.get<bool>(
      '/favorite/status',
      queryParameters: {'targetType': targetType, 'targetId': targetId},
    );
    return data ?? false;
  }
}
