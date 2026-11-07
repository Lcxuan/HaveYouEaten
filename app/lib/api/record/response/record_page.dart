import 'package:have_you_eaten/api/record/response/record_item.dart';

/// 吃过记录分页结果。
class RecordPage {
  const RecordPage({required this.items, required this.total});

  /// 当前页记录。
  final List<RecordItem> items;

  /// 全部记录总数。
  final int total;
}
