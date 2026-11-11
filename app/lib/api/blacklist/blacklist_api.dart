import 'package:have_you_eaten/api/blacklist/response/blacklist_item.dart';
import 'package:have_you_eaten/api/request.dart';

/// 黑名单接口。粒度：cuisine-菜系，poi-餐厅，recipe-菜谱。
class BlacklistApi {
  BlacklistApi._();

  /// 新增黑名单；服务端幂等。
  static Future<void> add({
    required String scope,
    required String targetValue,
    String? remark,
  }) async {
    await Request.post<void>(
      '/blacklist',
      data: {
        'scope': scope,
        'targetValue': targetValue,
        if (remark != null && remark.isNotEmpty) 'remark': remark,
      },
    );
  }

  /// 移除黑名单。
  static Future<void> remove({
    required String scope,
    required String targetValue,
  }) async {
    await Request.delete<void>(
      '/blacklist',
      queryParameters: {'scope': scope, 'targetValue': targetValue},
    );
  }

  /// 查询某个粒度下的黑名单。
  static Future<List<BlacklistItem>> list(String scope) async {
    final data = await Request.get<List<dynamic>>(
      '/blacklist/list',
      queryParameters: {'scope': scope},
    );
    return (data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BlacklistItem.fromJson)
        .toList();
  }
}
