import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/store/draw_preference_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';

/// 抽签偏好设置：保存后「在家吃」抽签自动套用。
class DrawPreferenceView extends ConsumerWidget {
  const DrawPreferenceView({super.key});

  static const _tasteOptions = ['微辣', '咸鲜', '下饭', '清淡', '酸甜'];
  static const _minuteOptions = [30, 45, 60, 90];
  static const _difficultyOptions = [(1, '简单'), (2, '中等'), (3, '困难')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(drawPreferenceProvider);
    final notifier = ref.read(drawPreferenceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('抽签偏好'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          const Text(
            '设置后，「在家吃」抽签会默认带上这些条件；首页筛选里仍可临时调整。',
            style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.7),
          ),
          const SizedBox(height: 14),
          _PreferenceCard(
            title: '口味',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final taste in _tasteOptions)
                  ChoiceChip(
                    label: Text(taste),
                    selected: filters.tastes.contains(taste),
                    onSelected: (_) =>
                        notifier.save(filters.toggleTaste(taste)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PreferenceCard(
            title: '最长时长',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in _minuteOptions)
                  ChoiceChip(
                    label: Text('$minutes 分钟内'),
                    selected: filters.maxCookMinutes == minutes,
                    onSelected: (selected) => notifier.save(
                      filters.withMaxCookMinutes(selected ? minutes : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PreferenceCard(
            title: '难度',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _difficultyOptions)
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: filters.difficulty == item.$1,
                    onSelected: (selected) => notifier.save(
                      filters.withDifficulty(selected ? item.$1 : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: filters.activeCount == 0
                ? null
                : () => notifier.reset(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: AppTheme.ink,
              side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
            ),
            child: const Text('清空偏好'),
          ),
        ],
      ),
    );
  }
}

/// 偏好分组卡片。
class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
