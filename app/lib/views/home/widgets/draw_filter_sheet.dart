import 'package:flutter/material.dart';

import 'package:have_you_eaten/styles/app_theme.dart';

/// 抽签筛选条件。
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

/// 打开筛选面板，返回 null 表示取消。
Future<DrawFilters?> showDrawFilterSheet(
  BuildContext context,
  DrawFilters initial,
) {
  return showModalBottomSheet<DrawFilters>(
    context: context,
    backgroundColor: AppTheme.paper,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => _DrawFilterSheet(initial: initial),
  );
}

class _DrawFilterSheet extends StatefulWidget {
  const _DrawFilterSheet({required this.initial});

  final DrawFilters initial;

  @override
  State<_DrawFilterSheet> createState() => _DrawFilterSheetState();
}

class _DrawFilterSheetState extends State<_DrawFilterSheet> {
  late Set<String> _tastes = Set<String>.from(widget.initial.tastes);
  late int? _minutes = widget.initial.maxCookMinutes;
  late int? _difficulty = widget.initial.difficulty;

  static const _tasteOptions = ['微辣', '咸鲜', '下饭', '清淡', '酸甜'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2D4C0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '筛选',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '口味',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final taste in _tasteOptions)
                    ChoiceChip(
                      label: Text(taste),
                      selected: _tastes.contains(taste),
                      onSelected: (_) {
                        setState(() {
                          _tastes = _setToggle(_tastes, taste);
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '时长',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in const [30, 45, 60, 90])
                    ChoiceChip(
                      label: Text('$minutes 分钟内'),
                      selected: _minutes == minutes,
                      onSelected: (selected) {
                        setState(() => _minutes = selected ? minutes : null);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '难度',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const [(1, '简单'), (2, '中等'), (3, '困难')])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: _difficulty == item.$1,
                      onSelected: (selected) {
                        setState(() => _difficulty = selected ? item.$1 : null);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _tastes = {};
                      _minutes = null;
                      _difficulty = null;
                    }),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppTheme.ink,
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                    ),
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      DrawFilters(
                        tastes: _tastes,
                        maxCookMinutes: _minutes,
                        difficulty: _difficulty,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('应用'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Set<String> _setToggle(Set<String> source, String value) {
    final next = Set<String>.from(source);
    if (!next.remove(value)) next.add(value);
    return next;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
