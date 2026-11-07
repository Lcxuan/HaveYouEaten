import 'package:have_you_eaten/api/cuisine/response/cuisine.dart';
import 'package:have_you_eaten/api/request.dart';

/// 菜系接口：字典查询。
class CuisineApi {
  CuisineApi._();

  /// 查询全部启用的菜系，按排序值升序。
  static Future<List<Cuisine>> list() async {
    final data = await Request.get<List<dynamic>>('/cuisine/list');
    return (data ?? const [])
        .map((item) => Cuisine.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
