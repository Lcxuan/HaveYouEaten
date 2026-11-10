/// 一条吃过记录。
class RecordItem {
  const RecordItem({
    required this.id,
    required this.recipeId,
    required this.name,
    required this.source,
    required this.eatenAt,
    this.remark,
  });

  /// 记录 id。
  final String id;

  /// 菜谱 id：在家吃时有值，出去吃为空。
  final String? recipeId;

  /// 名称：菜名或店名。
  final String name;

  /// 来源：roulette-抽签，manual-手动，ai_recommend-AI 推荐。
  final String source;

  /// 吃饭时间。
  final DateTime eatenAt;

  /// 备注。
  final String? remark;

  /// 是否能跳转菜谱详情。
  bool get canViewDetail => recipeId != null && recipeId!.isNotEmpty;

  /// 来源展示文案。
  String get sourceLabel => switch (source) {
    'roulette' => '抽签',
    'poi' => '出去吃',
    'manual' => '手动',
    'ai_recommend' => 'AI 推荐',
    _ => '记录',
  };

  factory RecordItem.fromJson(Map<String, dynamic> json) {
    final eatenAt = json['eatenAt'] as String?;
    return RecordItem(
      id: json['id']?.toString() ?? '',
      recipeId: json['recipeId']?.toString(),
      name: json['name'] as String? ?? '',
      source: json['source'] as String? ?? '',
      eatenAt:
          DateTime.tryParse(eatenAt ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      remark: json['remark'] as String?,
    );
  }
}
