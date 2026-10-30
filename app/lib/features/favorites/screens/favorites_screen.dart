import 'package:flutter/material.dart';

/// 收藏页：收藏与黑名单管理在 M3 实现（数据存服务端），当前为结构占位。
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('还没有收藏'),
            const SizedBox(height: 6),
            Text(
              '收藏菜谱 / 餐厅后，可以单独\n"从收藏里抽"',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
