import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/api/record/record_api.dart';
import 'package:have_you_eaten/api/record/response/record_item.dart';
import 'package:have_you_eaten/layout/main_layout.dart';
import 'package:have_you_eaten/store/auth_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/utils/error_util.dart';

/// 记录页：按天倒序展示最近 7 天吃过的菜，支持下拉刷新。
///
/// 记录只保存菜谱 id 与名称，在家吃（有 [RecordItem.recipeId]）可跳转菜谱详情；
/// 出去吃暂无详情入口。
class RecordView extends ConsumerStatefulWidget {
  const RecordView({super.key});

  @override
  ConsumerState<RecordView> createState() => RecordViewState();
}

class RecordViewState extends ConsumerState<RecordView> {
  static const _pageSize = 20;

  bool _loading = false;
  bool _loaded = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _pageNo = 1;
  int _total = 0;
  String? _error;
  List<RecordItem> _items = const [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 启动时登录态还在恢复，恢复完成后再加载。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(authProvider).loggedIn) {
        refresh();
      } else {
        setState(() => _loaded = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// 滚动接近底部时自动加载下一页。
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 240) _loadMore();
  }

  /// 重新拉取第一页；未登录时直接清空列表。
  Future<void> refresh() async {
    if (!ref.read(authProvider).loggedIn) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _total = 0;
        _hasMore = false;
        _pageNo = 1;
        _error = null;
        _loaded = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await RecordApi.list(pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _total = page.total;
        _pageNo = 1;
        _hasMore = page.items.length < page.total;
        _loading = false;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(error);
        _loading = false;
        _loaded = true;
      });
    }
  }

  /// 加载下一页并追加到列表末尾。
  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    if (!ref.read(authProvider).loggedIn) return;
    setState(() => _loadingMore = true);
    try {
      final page = await RecordApi.list(
        pageNo: _pageNo + 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _pageNo += 1;
        _items = [..._items, ...page.items];
        _total = page.total;
        _hasMore = _items.length < page.total;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.loggedIn && !(previous?.loggedIn ?? false)) {
        refresh();
      }
      if (!next.loggedIn && (previous?.loggedIn ?? false)) {
        setState(() {
          _items = const [];
          _error = null;
          _loaded = true;
        });
      }
    });

    final auth = ref.watch(authProvider);

    return MainLayout(
      title: '吃过记录',
      padding: EdgeInsets.zero,
      body: _buildBody(auth),
    );
  }

  Widget _buildBody(AuthState auth) {
    if (auth.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!auth.loggedIn) {
      return _Notice(
        icon: Icons.lock_outline_rounded,
        title: '登录后查看吃过记录',
        subtitle: '记录会同步保存，换设备也不会丢',
        actionLabel: '去登录',
        onAction: () => context.push('/login'),
      );
    }
    if (_error != null) {
      return _Notice(
        icon: Icons.cloud_off_rounded,
        title: '记录加载失败',
        subtitle: _error!,
        actionLabel: '重试',
        onAction: refresh,
      );
    }
    if (!_loaded || (_loading && _items.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      color: AppTheme.persimmon,
      onRefresh: refresh,
      child: _items.isEmpty ? _emptyList() : _recordList(),
    );
  }

  Widget _emptyList() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: _Notice(
              icon: Icons.menu_book_outlined,
              title: '还没有记录',
              subtitle: '在首页抽中想吃的菜，点「就吃这个，记一笔」',
            ),
          ),
        ),
      ),
    );
  }

  Widget _recordList() {
    final groups = <DateTime, List<RecordItem>>{};
    for (final item in _items) {
      final day = DateTime(
        item.eatenAt.year,
        item.eatenAt.month,
        item.eatenAt.day,
      );
      groups.putIfAbsent(day, () => []).add(item);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _SummaryCard(count: _total),
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
            child: Row(
              children: [
                Text(
                  _dayLabel(day),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _dateLabel(day),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9E8F80),
                  ),
                ),
              ],
            ),
          ),
          for (final item in groups[day]!) _RecordCard(item: item),
        ],
        _Footer(
          loading: _loadingMore,
          hasMore: _hasMore,
          count: _items.length,
        ),
      ],
    );
  }

  /// 今天 / 昨天 / 更早。
  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    return switch (diff) {
      0 => '今天',
      1 => '昨天',
      _ => '${day.month}月${day.day}日',
    };
  }

  /// 具体日期与星期。
  String _dateLabel(DateTime day) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${day.month}月${day.day}日 · ${weekdays[day.weekday - 1]}';
  }
}

/// 顶部统计：一共记录了多少顿。
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.persimmon.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              size: 22,
              color: AppTheme.persimmon,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '全部记录',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E8F80),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '吃了 $count 顿',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条记录卡片。
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.item});

  final RecordItem item;

  /// 按时间推断餐段。
  String get _meal {
    final hour = item.eatenAt.hour;
    if (hour >= 5 && hour < 10) return '早餐';
    if (hour >= 10 && hour < 15) return '午餐';
    if (hour >= 15 && hour < 21) return '晚餐';
    return '夜宵';
  }

  String get _time {
    final hour = item.eatenAt.hour.toString().padLeft(2, '0');
    final minute = item.eatenAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.canViewDetail
          ? () => context.push('/recipe/${item.recipeId}')
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x11000000)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _time,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _meal,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF9E8F80),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 3,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.persimmon.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _SourceChip(label: item.sourceLabel),
                      if (item.remark != null && item.remark!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.remark!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF9E8F80),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (item.canViewDetail)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFC4B5A5),
              ),
          ],
        ),
      ),
    );
  }
}

/// 来源标签。
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.persimmon.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.persimmon,
        ),
      ),
    );
  }
}

/// 列表底部：加载中 / 已全部加载。
class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.hasMore,
    required this.count,
  });

  final bool loading;
  final bool hasMore;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (hasMore || count == 0) return const SizedBox(height: 8);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '— 没有更多了 —',
          style: TextStyle(fontSize: 11.5, color: Color(0xFFB4A695)),
        ),
      ),
    );
  }
}

/// 空态 / 未登录 / 失败提示。
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.persimmon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 30, color: AppTheme.persimmon),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF9E8F80),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.persimmon,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
