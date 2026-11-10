import 'package:flutter/material.dart';

import 'package:have_you_eaten/api/restaurant/response/dine_cuisine.dart';
import 'package:have_you_eaten/api/restaurant/restaurant_api.dart';
import 'package:have_you_eaten/styles/app_theme.dart';

/// 出去吃筛选条件。
class DineOutFilters {
  const DineOutFilters({
    this.cuisineIds = const <int>{},
    this.maxCost,
    this.radius = 3000,
  });

  /// 抽签池菜系，留空表示由服务端按当前餐段自动抽。
  final Set<int> cuisineIds;

  /// 人均预算上限，空表示不限。
  final int? maxCost;

  /// 搜索半径（米）。
  final int radius;

  /// 已启用的条件数量，用于筛选胶囊角标。
  int get activeCount =>
      cuisineIds.length + (maxCost == null ? 0 : 1) + (radius == 3000 ? 0 : 1);

  DineOutFilters toggleCuisine(int id) {
    final next = Set<int>.from(cuisineIds);
    if (!next.remove(id)) next.add(id);
    return DineOutFilters(cuisineIds: next, maxCost: maxCost, radius: radius);
  }

  DineOutFilters withMaxCost(int? value) =>
      DineOutFilters(cuisineIds: cuisineIds, maxCost: value, radius: radius);

  DineOutFilters withRadius(int value) =>
      DineOutFilters(cuisineIds: cuisineIds, maxCost: maxCost, radius: value);

  DineOutFilters reset() => const DineOutFilters();
}

/// 打开筛选面板，返回 null 表示取消。
Future<DineOutFilters?> showDineOutFilterSheet(
  BuildContext context,
  DineOutFilters initial,
) {
  return showModalBottomSheet<DineOutFilters>(
    context: context,
    backgroundColor: AppTheme.paper,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => _DineOutFilterSheet(initial: initial),
  );
}

class _DineOutFilterSheet extends StatefulWidget {
  const _DineOutFilterSheet({required this.initial});

  final DineOutFilters initial;

  @override
  State<_DineOutFilterSheet> createState() => _DineOutFilterSheetState();
}

class _DineOutFilterSheetState extends State<_DineOutFilterSheet> {
  late Set<int> _cuisineIds = Set<int>.from(widget.initial.cuisineIds);
  late int? _maxCost = widget.initial.maxCost;
  late int _radius = widget.initial.radius;

  List<DineCuisine> _cuisines = const [];

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  Future<void> _loadCuisines() async {
    try {
      final cuisines = await RestaurantApi.cuisines();
      if (mounted) setState(() => _cuisines = cuisines);
    } catch (_) {
      // 菜系列表失败时隐藏菜系分组，其余筛选仍可用。
    }
  }

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
            if (_cuisines.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(
                title: '菜系（留空则由系统抽）',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cuisine in _cuisines)
                      ChoiceChip(
                        label: Text(cuisine.name),
                        selected: _cuisineIds.contains(
                          int.tryParse(cuisine.id) ?? -1,
                        ),
                        onSelected: (_) {
                          final id = int.tryParse(cuisine.id);
                          if (id == null) return;
                          setState(() {
                            final next = Set<int>.from(_cuisineIds);
                            if (!next.remove(id)) next.add(id);
                            _cuisineIds = next;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _Section(
              title: '人均预算',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const [
                    (30, '¥30 以内'),
                    (50, '¥50 以内'),
                    (100, '¥100 以内'),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: _maxCost == item.$1,
                      onSelected: (selected) {
                        setState(() => _maxCost = selected ? item.$1 : null);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '距离',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const [
                    (500, '500 m'),
                    (1000, '1 km'),
                    (3000, '3 km'),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: _radius == item.$1,
                      onSelected: (selected) {
                        setState(() => _radius = item.$1);
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
                      _cuisineIds = {};
                      _maxCost = null;
                      _radius = 3000;
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
                      DineOutFilters(
                        cuisineIds: _cuisineIds,
                        maxCost: _maxCost,
                        radius: _radius,
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
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
