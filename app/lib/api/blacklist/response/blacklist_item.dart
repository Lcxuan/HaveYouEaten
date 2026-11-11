/// 一条黑名单记录。
class BlacklistItem {
  const BlacklistItem({
    required this.id,
    required this.scope,
    required this.targetValue,
    this.remark,
    required this.createTime,
  });

  factory BlacklistItem.fromJson(Map<String, dynamic> json) {
    return BlacklistItem(
      id: json['id']?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
      targetValue: json['targetValue']?.toString() ?? '',
      remark: json['remark']?.toString(),
      createTime:
          DateTime.tryParse(json['createTime']?.toString() ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;

  /// 粒度：cuisine-菜系，poi-餐厅，recipe-菜谱。
  final String scope;

  /// 菜系名 / POI id / 菜谱 id。
  final String targetValue;

  /// 备注，餐厅与菜谱写名称便于展示。
  final String? remark;

  final DateTime createTime;

  /// 展示名称：优先备注，其次屏蔽值。
  String get displayName {
    final value = remark?.trim() ?? '';
    return value.isEmpty ? targetValue : value;
  }
}
