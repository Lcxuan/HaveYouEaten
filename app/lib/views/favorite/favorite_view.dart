import 'package:flutter/material.dart';

import 'package:have_you_eaten/layout/main_layout.dart';
import 'package:have_you_eaten/styles/app_theme.dart';

/// 收藏页签：后续展示收藏的菜谱 / 餐厅与黑名单。
class FavoriteView extends StatelessWidget {
  const FavoriteView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: '收藏',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 56, color: AppTheme.yolk),
            SizedBox(height: 12),
            Text('收藏与黑名单待实现'),
          ],
        ),
      ),
    );
  }
}
