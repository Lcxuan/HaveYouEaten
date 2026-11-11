import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/api/blacklist/blacklist_api.dart';
import 'package:have_you_eaten/api/blacklist/response/blacklist_item.dart';
import 'package:have_you_eaten/api/restaurant/response/dine_cuisine.dart';
import 'package:have_you_eaten/api/restaurant/restaurant_api.dart';
import 'package:have_you_eaten/store/auth_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/utils/error_util.dart';

/// 黑名单管理：菜系 / 餐厅 / 菜谱三个分组，支持新增菜系与移除。
class BlacklistView extends ConsumerStatefulWidget {
  const BlacklistView({super.key});

  @override
  ConsumerState<BlacklistView> createState() => _BlacklistViewState();
}

class _BlacklistViewState extends ConsumerState<BlacklistView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  List<DineCuisine> _cuisines = const [];
  List<BlacklistItem> _blockedCuisines = const [];
  List<BlacklistItem> _blockedPois = const [];
  List<BlacklistItem> _blockedRecipes = const [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

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

  Future<void> _load() async {
    if (!ref.read(authProvider).loggedIn) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        BlacklistApi.list('cuisine'),
        BlacklistApi.list('poi'),
        BlacklistApi.list('recipe'),
        RestaurantApi.cuisines(),
      ]);
      if (!mounted) return;
      setState(() {
        _blockedCuisines = result[0] as List<BlacklistItem>;
        _blockedPois = result[1] as List<BlacklistItem>;
        _blockedRecipes = result[2] as List<BlacklistItem>;
        _cuisines = result[3] as List<DineCuisine>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCuisine(DineCuisine cuisine) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await BlacklistApi.add(
        scope: 'cuisine',
        targetValue: cuisine.name,
        remark: cuisine.name,
      );
      final list = await BlacklistApi.list('cuisine');
      if (!mounted) return;
      setState(() => _blockedCuisines = list);
      _showMessage('已拉黑「${cuisine.name}」');
    } catch (error) {
      if (mounted) _showMessage(friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(BlacklistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('移出黑名单'),
        content: Text('确定恢复推荐「${item.displayName}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('移出'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await BlacklistApi.remove(scope: item.scope, targetValue: item.targetValue);
      if (!mounted) return;
      setState(() {
        switch (item.scope) {
          case 'cuisine':
            _blockedCuisines =
                _blockedCuisines.where((e) => e.id != item.id).toList();
          case 'poi':
            _blockedPois = _blockedPois.where((e) => e.id != item.id).toList();
          case 'recipe':
            _blockedRecipes =
                _blockedRecipes.where((e) => e.id != item.id).toList();
        }
      });
      _showMessage('已移出黑名单');
    } catch (error) {
      if (mounted) _showMessage(friendlyError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).loggedIn;
    ref.listen(authProvider.select((state) => state.loggedIn), (_, next) {
      if (next) _load();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('黑名单管理'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        bottom: loggedIn
            ? TabBar(
                controller: _tabController,
                labelColor: AppTheme.persimmon,
                unselectedLabelColor: Colors.black45,
                indicatorColor: AppTheme.persimmon,
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: '菜系'),
                  Tab(text: '餐厅'),
                  Tab(text: '菜谱'),
                ],
              )
            : null,
      ),
      body: !loggedIn
          ? _LoginHint(onLogin: () => context.go('/login'))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
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
        _buildCuisineTab(),
        _buildListTab(
          items: _blockedPois,
          emptyText: '还没有拉黑的餐厅\n在「出去吃」结果卡右上角选「不再推荐这家」',
        ),
        _buildListTab(
          items: _blockedRecipes,
          emptyText: '还没有拉黑的菜谱\n在菜谱详情右上角选「不再推荐这道菜」',
        ),
      ],
    );
  }

  /// 菜系页：上方是可拉黑的菜系，下方是已有的黑名单。
  Widget _buildCuisineTab() {
    final blockedNames = _blockedCuisines
        .map((item) => item.targetValue)
        .toSet();
    final available = _cuisines
        .where((cuisine) => !blockedNames.contains(cuisine.name))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        const Text(
          '不想吃的菜系，抽签时会被跳过',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 10),
        if (available.isEmpty)
          const Text(
            '全部菜系都已拉黑，先去下方移除几个吧',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cuisine in available)
                ActionChip(
                  label: Text('+ ${cuisine.name}'),
                  onPressed: _busy ? null : () => _addCuisine(cuisine),
                  backgroundColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.ink,
                  ),
                  side: BorderSide(
                    color: AppTheme.ink.withValues(alpha: 0.12),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 18),
        const Text(
          '已拉黑',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        if (_blockedCuisines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '还没有拉黑的菜系',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          )
        else
          for (final item in _blockedCuisines)
            _BlacklistTile(item: item, onRemove: () => _remove(item)),
      ],
    );
  }

  Widget _buildListTab({
    required List<BlacklistItem> items,
    required String emptyText,
  }) {
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 340,
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _BlacklistTile(
                  item: item,
                  onRemove: () => _remove(item),
                );
              },
            ),
    );
  }
}

/// 一条黑名单记录。
class _BlacklistTile extends StatelessWidget {
  const _BlacklistTile({required this.item, required this.onRemove});

  final BlacklistItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.scope) {
      'cuisine' => Icons.restaurant_menu_rounded,
      'poi' => Icons.storefront_rounded,
      _ => Icons.rice_bowl_rounded,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '拉黑于 ${_formatDate(item.createTime)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: '移出黑名单',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.black45,
            ),
          ),
        ],
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
          const Icon(Icons.block_rounded, size: 56, color: AppTheme.yolk),
          const SizedBox(height: 12),
          const Text(
            '登录后管理黑名单',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onLogin, child: const Text('去登录')),
        ],
      ),
    );
  }
}
