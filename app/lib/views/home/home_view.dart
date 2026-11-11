import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/views/favorite/favorite_view.dart';
import 'package:have_you_eaten/views/home/tabs/home_tab.dart';
import 'package:have_you_eaten/views/record/record_view.dart';
import 'package:have_you_eaten/views/settings/settings_view.dart';

/// 主框架：底部四个入口，对应原型的「首页 / 记录 / 收藏 / 设置」。
///
/// 未登录也可浏览，登录入口放在「设置」页；用 [IndexedStack]
/// 保留各页状态，切换页签时不会重建页面。
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _index = 0;

  /// 记录页 State，切到该页签时触发刷新，保证首页刚记的一笔能立刻看到。
  final _recordKey = GlobalKey<RecordViewState>();

  /// 收藏页 State，切到该页签时刷新，保证刚收藏的内容立刻可见。
  final _favoriteKey = GlobalKey<FavoriteViewState>();

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.ramen_dining_outlined), label: '首页'),
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: '记录'),
    NavigationDestination(icon: Icon(Icons.star_outline_rounded), label: '收藏'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    // 页面按下标创建，IndexedStack 会保留各页 State。
    final pages = <Widget>[
      HomeTab(
        isActive: _index == 0,
        onOpenSettings: () => setState(() => _index = 3),
      ),
      RecordView(key: _recordKey),
      FavoriteView(key: _favoriteKey),
      const SettingsView(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0x11000000))),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: Colors.white,
          indicatorColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: (index) {
            setState(() => _index = index);
            if (index == 1) _recordKey.currentState?.refresh();
            if (index == 2) _favoriteKey.currentState?.refresh();
          },
          destinations: _destinations,
        ),
      ),
    );
  }
}
