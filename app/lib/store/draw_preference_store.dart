import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 抽签偏好：口味、最长时长、难度。
class DrawFilters {
  const DrawFilters({
    this.tastes = const <String>{},
    this.maxCookMinutes,
    this.difficulty,
  });

  final Set<String> tastes;
  final int? maxCookMinutes;
  final int? difficulty;

  /// 已启用的条件数量，用于筛选按钮角标。
  int get activeCount =>
      tastes.length +
      (maxCookMinutes == null ? 0 : 1) +
      (difficulty == null ? 0 : 1);

  DrawFilters toggleTaste(String taste) {
    final next = Set<String>.from(tastes);
    if (!next.remove(taste)) next.add(taste);
    return DrawFilters(
      tastes: next,
      maxCookMinutes: maxCookMinutes,
      difficulty: difficulty,
    );
  }

  DrawFilters withMaxCookMinutes(int? value) => DrawFilters(
    tastes: tastes,
    maxCookMinutes: value,
    difficulty: difficulty,
  );

  DrawFilters withDifficulty(int? value) => DrawFilters(
    tastes: tastes,
    maxCookMinutes: maxCookMinutes,
    difficulty: value,
  );

  DrawFilters reset() => const DrawFilters();
}

/// 抽签偏好存储：本地持久化，修改后「在家吃」抽签自动使用。
final drawPreferenceProvider =
    NotifierProvider<DrawPreferenceNotifier, DrawFilters>(
      DrawPreferenceNotifier.new,
    );

class DrawPreferenceNotifier extends Notifier<DrawFilters> {
  static const _tastesKey = 'draw_pref_tastes';
  static const _minutesKey = 'draw_pref_max_minutes';
  static const _difficultyKey = 'draw_pref_difficulty';

  @override
  DrawFilters build() {
    _restore();
    return const DrawFilters();
  }

  /// 从本地读取，读到后更新状态。
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final tastes = prefs.getStringList(_tastesKey) ?? const [];
    state = DrawFilters(
      tastes: tastes.toSet(),
      maxCookMinutes: prefs.getInt(_minutesKey),
      difficulty: prefs.getInt(_difficultyKey),
    );
  }

  /// 保存并立即生效。
  Future<void> save(DrawFilters filters) async {
    state = filters;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tastesKey, filters.tastes.toList());
    final minutes = filters.maxCookMinutes;
    if (minutes == null) {
      await prefs.remove(_minutesKey);
    } else {
      await prefs.setInt(_minutesKey, minutes);
    }
    final difficulty = filters.difficulty;
    if (difficulty == null) {
      await prefs.remove(_difficultyKey);
    } else {
      await prefs.setInt(_difficultyKey, difficulty);
    }
  }

  /// 清空全部偏好。
  Future<void> reset() => save(const DrawFilters());
}
