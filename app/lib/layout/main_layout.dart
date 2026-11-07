import 'package:flutter/material.dart';

/// 页面通用骨架：统一内边距与可滚动内容区。
///
/// 后续页面统一通过该布局包裹，避免每个页面重复写 Scaffold 配置。
class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.padding = const EdgeInsets.all(20),
  });

  /// 页面标题。
  final String title;

  /// 页面内容。
  final Widget body;

  /// 右上角操作按钮。
  final List<Widget>? actions;

  /// 内容区内边距。
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Padding(padding: padding, child: body),
    );
  }
}
