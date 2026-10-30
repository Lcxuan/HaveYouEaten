import 'package:flutter/material.dart';

/// 吃过记录页：时间线与本周统计在 M3 实现（数据存服务端），当前为结构占位。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('吃过什么')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('还没有记录'),
            const SizedBox(height: 6),
            Text(
              '抽中并确认"就吃这个"后会自动记录\n接口在 M1 接入，时间线在 M3 完善',
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
