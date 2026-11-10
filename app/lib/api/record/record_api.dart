import 'package:have_you_eaten/api/record/response/record_item.dart';
import 'package:have_you_eaten/api/record/response/record_page.dart';
import 'package:have_you_eaten/api/request.dart';

/// 吃过记录接口。
class RecordApi {
  RecordApi._();

  /// 记一笔：抽中菜品后写入记录。
  static Future<void> create({
    required String recipeId,
    String source = 'roulette',
  }) async {
    await Request.post<void>(
      '/record',
      data: {'recipeId': recipeId, 'source': source},
    );
  }

  /// 记一笔：出去吃选好店后写入记录。
  static Future<void> createPoi({
    required String poiId,
    required String poiName,
  }) async {
    await Request.post<void>(
      '/record',
      data: {'poiId': poiId, 'poiName': poiName, 'source': 'poi'},
    );
  }

  /// 分页查询全部记录，按吃饭时间倒序。
  static Future<RecordPage> list({int pageNo = 1, int pageSize = 20}) async {
    final data = await Request.get<Map<String, dynamic>>(
      '/record/list',
      queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
    );
    final list = data?['list'] as List<dynamic>? ?? const [];
    final items = list
        .whereType<Map<String, dynamic>>()
        .map(RecordItem.fromJson)
        .toList();
    // 服务端 Long 序列化为字符串，这里兼容字符串与数字两种形式。
    final total =
        int.tryParse('${data?['total'] ?? ''}') ?? items.length;
    return RecordPage(items: items, total: total);
  }
}
