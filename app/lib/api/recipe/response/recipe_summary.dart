/// 菜谱摘要：抽签结果与列表共用。
class RecipeSummary {
  const RecipeSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisines,
    required this.difficulty,
    required this.cookMinutes,
    required this.tags,
    required this.imageUrl,
    required this.source,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    return RecipeSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      cuisines: _toCuisines(json),
      difficulty: _toInt(json['difficulty']),
      cookMinutes: _toInt(json['cookMinutes']),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String description;

  /// 菜系名称列表，可有多个。
  final List<String> cuisines;
  final int? difficulty;
  final int? cookMinutes;
  final List<String> tags;
  final String imageUrl;

  /// 来源：ai / import / manual。
  final String source;

  /// 主菜系（第一个），用于转盘扇区与简要展示。
  String get primaryCuisine => cuisines.isEmpty ? '' : cuisines.first;

  /// 是否为 AI 生成内容。
  bool get isAiGenerated => source == 'ai';
}

/// 兼容新旧返回：优先读 cuisines 数组，旧接口读单个 cuisine 字符串。
List<String> _toCuisines(Map<String, dynamic> json) {
  final list = json['cuisines'];
  if (list is List) {
    return list
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item['name']?.toString() ?? '';
          }
          return item.toString();
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }
  final single = json['cuisine']?.toString() ?? '';
  return single.isEmpty ? const [] : [single];
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('${value ?? ''}');
}
