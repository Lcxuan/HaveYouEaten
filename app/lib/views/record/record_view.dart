import 'package:flutter/material.dart';

import 'package:have_you_eaten/layout/main_layout.dart';
import 'package:have_you_eaten/styles/app_theme.dart';

/// 记录页签：后续展示按天分组的吃过记录与本周统计。
class RecordView extends StatelessWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: '吃过记录',
      body: _Placeholder(
        icon: Icons.menu_book_rounded,
        text: '吃过记录待实现',
      ),
    );
  }
}

/// 统一的空态占位。
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppTheme.persimmon),
          const SizedBox(height: 12),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
