import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/app/app_router.dart';

/// 二级页面共用的标题栏和安全区域布局：有上一页则返回，否则回到首页。
class StandardPage extends StatelessWidget {
  const StandardPage({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canReturnToPreviousPage = context.canPop();
    return PopScope(
      canPop: canReturnToPreviousPage,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.goNamed(AppRouteNames.home);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            tooltip: '返回',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRouteNames.home);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(child: child),
      ),
    );
  }
}
