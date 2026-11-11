import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/api/favorite/favorite_api.dart';
import 'package:have_you_eaten/api/favorite/response/favorite_item.dart';
import 'package:have_you_eaten/api/restaurant/response/restaurant.dart';
import 'package:have_you_eaten/layout/main_layout.dart';
import 'package:have_you_eaten/store/auth_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/utils/error_util.dart';
import 'package:have_you_eaten/utils/restaurant_launcher.dart';

/// 收藏页签：菜谱 / 餐厅两个分组，支持取消收藏与跳转。
class FavoriteView extends ConsumerStatefulWidget {
  const FavoriteView({super.key});

  @override
  ConsumerState<FavoriteView> createState() => FavoriteViewState();
}

class FavoriteViewState extends ConsumerState<FavoriteView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  List<FavoriteItem> _recipes = const [];
  List<FavoriteItem> _restaurants = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authProvider).loggedIn) _load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 切到收藏页签时刷新，保证首页刚收藏的内容立刻可见。
  Future<void> refresh() => _load();

  Future<void> _load() async {
    if (!ref.read(authProvider).loggedIn) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        FavoriteApi.list(targetType: 'recipe', pageSize: 50),
        FavoriteApi.list(targetType: 'restaurant', pageSize: 50),
      ]);
      if (!mounted) return;
      setState(() {
        _recipes = result[0].items;
        _restaurants = result[1].items;
      });
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).loggedIn;
    ref.listen(authProvider.select((state) => state.loggedIn), (_, next) {
      if (next) {
        _load();
      } else {
        setState(() {
          _recipes = const [];
          _restaurants = const [];
          _error = null;
        });
      }
    });

    return MainLayout(
      title: '收藏',
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.persimmon,
            unselectedLabelColor: Colors.black45,
            indicatorColor: AppTheme.persimmon,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: '菜谱'),
              Tab(text: '餐厅'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: !loggedIn
                ? _LoginHint(onLogin: () => context.go('/login'))
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _recipes.isEmpty && _restaurants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _load, child: const Text('重新加载')),
          ],
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _FavoriteList(
          items: _recipes,
          emptyText: '还没有收藏的菜谱\n在家吃抽到喜欢的，点右上角收藏',
          onRefresh: _load,
          onTap: (item) => context.push('/recipe/${item.targetId}'),
          onRemove: _unfavorite,
        ),
        _FavoriteList(
          items: _restaurants,
          emptyText: '还没有收藏的餐厅\n出去吃翻到喜欢的，点星标收藏',
          onRefresh: _load,
          onTap: _openRestaurant,
          onRemove: _unfavorite,
        ),
      ],
    );
  }

  /// 直接使用收藏时保存的快照，不再请求高德详情。
  Future<void> _openRestaurant(FavoriteItem item) async {
    final restaurant =
        item.restaurant ?? Restaurant(poiId: item.targetId, name: item.name);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.paper,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => _FavoriteRestaurantSheet(
        restaurant: restaurant,
        incomplete: item.restaurant == null,
        onNavigate: () => RestaurantLauncher.navigate(restaurant),
      ),
    );
  }

  Future<void> _unfavorite(FavoriteItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('取消收藏'),
        content: Text('确定不再收藏「${item.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.chili),
            child: const Text('取消收藏'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FavoriteApi.remove(
        targetType: item.targetType,
        targetId: item.targetId,
      );
      if (!mounted) return;
      setState(() {
        if (item.isRecipe) {
          _recipes = _recipes.where((e) => e.id != item.id).toList();
        } else {
          _restaurants = _restaurants.where((e) => e.id != item.id).toList();
        }
      });
      _showMessage('已取消收藏');
    } catch (error) {
      if (mounted) _showMessage(friendlyError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 收藏列表：支持下拉刷新。
class _FavoriteList extends StatelessWidget {
  const _FavoriteList({
    required this.items,
    required this.emptyText,
    required this.onRefresh,
    required this.onTap,
    required this.onRemove,
  });

  final List<FavoriteItem> items;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final void Function(FavoriteItem item) onTap;
  final Future<void> Function(FavoriteItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 320,
                  child: Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black45,
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _FavoriteTile(
                  item: item,
                  onTap: () => onTap(item),
                  onRemove: () => onRemove(item),
                );
              },
            ),
    );
  }
}

/// 单条收藏：图标 + 名称 + 收藏时间 + 取消收藏。
class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.persimmon.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.isRecipe
                      ? Icons.rice_bowl_rounded
                      : Icons.storefront_rounded,
                  size: 20,
                  color: AppTheme.persimmon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '收藏于 ${_formatDate(item.createTime)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: '取消收藏',
                icon: const Icon(
                  Icons.star_rounded,
                  size: 22,
                  color: AppTheme.yolk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '${time.year}-$month-$day';
  }
}

/// 未登录提示。
class _LoginHint extends StatelessWidget {
  const _LoginHint({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 56, color: AppTheme.yolk),
          const SizedBox(height: 12),
          const Text(
            '登录后同步收藏',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '收藏的菜谱和餐厅会保存在云端',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onLogin, child: const Text('去登录')),
        ],
      ),
    );
  }
}

/// 收藏餐厅的信息弹层：详情 + 导航。
class _FavoriteRestaurantSheet extends StatelessWidget {
  const _FavoriteRestaurantSheet({
    required this.restaurant,
    required this.onNavigate,
    this.incomplete = false,
  });

  final Restaurant restaurant;
  final Future<bool> Function() onNavigate;

  /// 旧收藏没有快照时为 true，提示用户重新收藏补全信息。
  final bool incomplete;

  @override
  Widget build(BuildContext context) {
    final metas = <Widget>[
      if (restaurant.rating != null)
        _Meta(
          icon: Icons.star_rounded,
          text: restaurant.rating!.toStringAsFixed(1),
          color: AppTheme.yolk,
        ),
      if (restaurant.costText.isNotEmpty)
        _Meta(icon: Icons.payments_rounded, text: restaurant.costText),
      if (restaurant.distanceText.isNotEmpty)
        _Meta(
          icon: Icons.near_me_rounded,
          text: '距你 ${restaurant.distanceText}',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Text(
            restaurant.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          if (metas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 6, children: metas),
          ],
          if (restaurant.address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: Colors.black45,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    restaurant.address,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (incomplete) ...[
            const SizedBox(height: 10),
            const Text(
              '这条收藏缺少详细信息，取消后重新收藏即可补全',
              style: TextStyle(fontSize: 11.5, color: Colors.black45),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final opened = await onNavigate();
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('无法打开导航，请稍后重试')),
                  );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.scallion,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.navigation_rounded, size: 17),
            label: const Text('导航去这里'),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.black45),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
        ),
      ],
    );
  }
}
