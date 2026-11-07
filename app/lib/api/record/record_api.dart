import 'package:have_you_eaten/api/request.dart';

/// 吃过记录接口。
class RecordApi {
  RecordApi._();

  /// 记一笔：抽中菜品后写入记录。
  static Future<void> create({required String recipeId, String source = 'roulette'}) async {
    await Request.post<void>(
      '/record',
      data: {'recipeId': recipeId, 'source': source},
    );
  }
}
