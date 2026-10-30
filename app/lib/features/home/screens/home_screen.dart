import 'package:flutter/material.dart';

import 'package:have_you_eaten/theme/app_theme.dart';

/// 首页：转盘抽签主入口；抽签交互与双模式切换在 M1 实现，当前为结构占位。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.persimmon,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  '吃了吗？',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              '今天吃什么？\n摇一摇就知道。',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '在家吃抽菜谱，出去吃抽餐厅。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppTheme.ink,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('美食转盘', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    const Text(
                      '抽签功能开发中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonal(
                      onPressed: null,
                      child: const Text('M1 实现：转盘 + 摇一摇'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
