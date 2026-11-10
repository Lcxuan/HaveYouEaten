import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/api/record/record_api.dart';
import 'package:have_you_eaten/api/restaurant/restaurant_api.dart';
import 'package:have_you_eaten/api/restaurant/response/dine_cuisine.dart';
import 'package:have_you_eaten/api/restaurant/response/restaurant.dart';
import 'package:have_you_eaten/api/restaurant/response/restaurant_deck.dart';
import 'package:have_you_eaten/store/auth_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/utils/error_util.dart';
import 'package:have_you_eaten/utils/location_service.dart';
import 'package:have_you_eaten/views/home/widgets/dine_out_filter_sheet.dart';
import 'package:have_you_eaten/views/home/widgets/dine_out_result_sheet.dart';
import 'package:have_you_eaten/views/home/widgets/restaurant_deck.dart';

/// 出去吃阶段：未开始 / 抽菜系 / 翻牌中。
enum _DineOutStage { idle, revealing, browsing }

/// 出去吃页签：先抽菜系，再一家家翻附近的店。
class DineOutTab extends ConsumerStatefulWidget {
  const DineOutTab({super.key});

  @override
  ConsumerState<DineOutTab> createState() => _DineOutTabState();
}

class _DineOutTabState extends ConsumerState<DineOutTab>
    with SingleTickerProviderStateMixin {
  _DineOutStage _stage = _DineOutStage.idle;
  DineOutFilters _filters = const DineOutFilters();
  RestaurantDeck? _deck;
  int _index = 0;
  String? _error;
  List<DineCuisine> _cuisines = const [];
  AppLocation? _location;

  /// 防重入：拉绳、按钮可能同时触发。
  bool _starting = false;

  /// 抽菜系滚动展示：未返回前先快速轮播候选菜系名。
  Timer? _revealTimer;
  String _revealName = '';

  /// 菜系已落定，短暂停留后再翻出第一张店卡。
  bool _revealLanded = false;

  /// 请求序号：重开一轮时丢弃旧请求的回调。
  int _requestId = 0;

  /// 菜系列表缺失时的轮播兜底。
  static const _fallbackCuisines = [
    '川菜', '粤菜', '湘菜', '火锅', '江浙菜', '东北菜', '西北菜', '云贵菜',
    '海鲜', '日料', '韩料', '西餐', '东南亚菜', '茶餐厅', '咖啡', '甜品',
  ];

  /// 翻牌动画：当前卡飞出、下一张升起。
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  bool _flipping = false;

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _flip.dispose();
    super.dispose();
  }

  Future<void> _loadCuisines() async {
    try {
      final cuisines = await RestaurantApi.cuisines();
      if (mounted) setState(() => _cuisines = cuisines);
    } catch (error) {
      debugPrint('加载菜系列表失败：$error');
    }
  }

  Future<void> _openFilters() async {
    final result = await showDineOutFilterSheet(context, _filters);
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    // 条件变了，旧卡片不再可信，重新抽菜系发牌
    if (_stage == _DineOutStage.browsing) await _start();
  }

  /// 发牌：先滚动抽菜系给用户看，再请求服务端拉附近的店。
  ///
  /// [excludeCuisineIds] 用于「换菜系」，避免连着抽到同一个菜系。
  Future<void> _start({List<int> excludeCuisineIds = const []}) async {
    if (_starting) return;
    if (!ref.read(authProvider).loggedIn) {
      _showMessage('请先在底部「设置」页登录后再开始');
      return;
    }

    final previousDeck = _deck;
    final previousIndex = _index;
    final requestId = ++_requestId;
    _beginReveal();

    final stopwatch = Stopwatch()..start();
    try {
      final location = await _resolveLocation();
      if (!_isCurrent(requestId)) return;
      if (location == null) {
        _restorePrevious(
          previousDeck,
          previousIndex,
          '定位失败，请检查定位权限后重试',
        );
        return;
      }

      final deck = await RestaurantApi.deck(
        lng: location.longitude,
        lat: location.latitude,
        radius: _filters.radius,
        cuisineIds: _filters.cuisineIds.toList(),
        excludeCuisineIds: excludeCuisineIds,
        maxCost: _filters.maxCost,
      );
      if (!_isCurrent(requestId)) return;

      // 菜系轮播至少展示 900ms，避免一闪而过
      final remain = 900 - stopwatch.elapsedMilliseconds;
      if (remain > 0) {
        await Future<void>.delayed(Duration(milliseconds: remain));
      }
      if (!_isCurrent(requestId)) return;

      if (deck.isEmpty) {
        _restorePrevious(
          previousDeck,
          previousIndex,
          '附近没有符合条件的餐厅，试试扩大距离或取消筛选',
        );
        if (previousDeck != null) _showMessage('这个菜系附近没有店，再换一个吧');
        return;
      }

      // 菜系先落定停留，让用户看清抽到了什么，再翻出第一张卡
      _landReveal(deck.cuisineName);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!_isCurrent(requestId)) return;

      setState(() {
        _deck = deck;
        _index = 0;
        _stage = _DineOutStage.browsing;
        _error = null;
        _revealLanded = false;
      });
    } catch (error) {
      if (!_isCurrent(requestId)) return;
      final message = friendlyError(error);
      _restorePrevious(
        previousDeck,
        previousIndex,
        previousDeck == null ? message : null,
      );
      if (previousDeck != null) _showMessage(message);
    } finally {
      if (_isCurrent(requestId)) setState(() => _starting = false);
    }
  }

  /// 每次发牌都重新定位，保证换了地方后立即用新坐标；
  /// 定位失败时退回上一次坐标，首次失败才提示。
  Future<AppLocation?> _resolveLocation() async {
    final fresh = await LocationService.locate();
    if (fresh == null) return _location;

    _location = fresh;
    debugPrint(
      '出去吃定位：lng=${fresh.longitude}, lat=${fresh.latitude}, '
      '精度=${fresh.accuracy}m, 来自缓存=${fresh.fromCache}',
    );
    if (fresh.isApproximate) {
      _showMessage('当前定位精度较低，建议开启精确位置');
    }
    return fresh;
  }

  /// 当前请求是否仍然有效（页面未销毁且未开始新一轮）。
  bool _isCurrent(int requestId) => mounted && requestId == _requestId;

  /// 开始轮播候选菜系，先把「正在抽」的过程展示出来。
  void _beginReveal() {
    _revealTimer?.cancel();
    final pool = _revealPool;
    setState(() {
      _starting = true;
      _stage = _DineOutStage.revealing;
      _error = null;
      _revealLanded = false;
      _revealName = pool[Random().nextInt(pool.length)];
    });
    _revealTimer = Timer.periodic(const Duration(milliseconds: 85), (_) {
      if (!mounted) return;
      final names = _revealPool;
      setState(() => _revealName = names[Random().nextInt(names.length)]);
    });
  }

  /// 菜系落定：停止轮播并高亮展示。
  void _landReveal(String name) {
    _revealTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _revealName = name;
      _revealLanded = true;
    });
  }

  /// 轮播范围：优先用户勾选的菜系，其次是全部菜系。
  List<String> get _revealPool {
    final selected = _cuisines
        .where(
          (cuisine) => _filters.cuisineIds.contains(int.tryParse(cuisine.id)),
        )
        .map((cuisine) => cuisine.name)
        .toList();
    if (selected.isNotEmpty) return selected;
    final all = _cuisines.map((cuisine) => cuisine.name).toList();
    return all.isEmpty ? _fallbackCuisines : all;
  }

  /// 失败时回到发牌前的状态：有旧牌就继续翻，没有就回到卡背。
  void _restorePrevious(
    RestaurantDeck? previousDeck,
    int previousIndex,
    String? error,
  ) {
    _revealTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _deck = previousDeck;
      _index = previousIndex;
      _stage = previousDeck == null ? _DineOutStage.idle : _DineOutStage.browsing;
      _error = error;
      _revealLanded = false;
    });
  }

  /// 换一家：同一菜系本地翻下一张，翻到底则改为换菜系。
  Future<void> _next() async {
    final deck = _deck;
    if (deck == null || _flipping) return;
    if (_index + 1 >= deck.options.length) {
      await _switchCuisine();
      return;
    }

    setState(() => _flipping = true);
    await _flip.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _index += 1;
      _flipping = false;
    });
    _flip.reset();
  }

  /// 换菜系：排除当前菜系后重发整叠；只勾了一个菜系时无意义。
  Future<void> _switchCuisine() async {
    final cuisineId = int.tryParse(_deck?.cuisineId ?? '');
    await _start(excludeCuisineIds: cuisineId == null ? const [] : [cuisineId]);
  }

  bool get _canSwitchCuisine {
    // 用户只选了一个菜系时，「换菜系」永远还是它
    if (_filters.cuisineIds.length == 1) return false;
    // 菜系列表未加载成功时交给服务端判断，不提前隐藏入口
    if (_cuisines.isEmpty) return true;
    final available = _filters.cuisineIds.isEmpty
        ? _cuisines.length
        : _cuisines
              .where(
                (cuisine) =>
                    _filters.cuisineIds.contains(int.tryParse(cuisine.id)),
              )
              .length;
    return available != 1;
  }

  Future<void> _confirm() async {
    final restaurant = _currentRestaurant;
    if (restaurant == null) return;
    final again = await showDineOutResultSheet(
      context,
      restaurant: restaurant,
      loggedIn: ref.read(authProvider).loggedIn,
      onRecord: () => _record(restaurant),
    );
    if (!mounted || !again) return;
    await _next();
  }

  Future<bool> _record(Restaurant restaurant) async {
    try {
      await RecordApi.createPoi(poiId: restaurant.poiId, poiName: restaurant.name);
      if (mounted) _showMessage('已记一笔');
      return true;
    } catch (error) {
      if (mounted) _showMessage(friendlyError(error));
      return false;
    }
  }

  Restaurant? get _currentRestaurant {
    final deck = _deck;
    if (deck == null || deck.options.isEmpty) return null;
    return deck.options[_index.clamp(0, deck.options.length - 1)];
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(
          filters: _filters,
          cuisines: _cuisines,
          // 抽菜系过程中不允许改条件，避免结果与筛选不一致
          onOpen: _starting ? () {} : _openFilters,
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    return switch (_stage) {
      _DineOutStage.revealing => _buildReveal(),
      _DineOutStage.idle => _buildIdle(),
      _DineOutStage.browsing => _buildBrowsing(),
    };
  }

  /// 抽菜系：候选名快速轮播，落定后停在高亮菜系上。
  Widget _buildReveal() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _revealLanded ? '今天就吃' : '正在抽菜系…',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: _revealLanded ? AppTheme.persimmon : Colors.black45,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: restaurantCardWidth,
              height: restaurantCardHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _revealLanded
                      ? AppTheme.persimmon
                      : AppTheme.ink.withValues(alpha: 0.08),
                  width: _revealLanded ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.10),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 38)),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: Tween<double>(begin: 0.86, end: 1).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Text(
                      _revealName,
                      key: ValueKey('$_revealName-$_revealLanded'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: _revealLanded ? AppTheme.persimmon : AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _revealLanded ? '正在找附近的店…' : '再等一下，马上就好',
              style: const TextStyle(fontSize: 11.5, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  /// 未开始：绳子 + 整叠牌背 + 开始按钮。
  Widget _buildIdle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PullCord(
                  enabled: !_starting,
                  onTriggered: () => _start(),
                ),
                const SizedBox(height: 2),
                IdleCardStack(message: _error),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _starting ? null : () => _start(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 13,
                    ),
                  ),
                  child: const Text('开始替我做决定'),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? '拉一下绳子，也可以开始',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _error == null ? Colors.black38 : AppTheme.chili,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 翻牌中：菜系条 + 卡牌堆 + 换一家 / 就吃这个。
  Widget _buildBrowsing() {
    final deck = _deck;
    if (deck == null || deck.options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        _CuisineBar(
          deck: deck,
          canSwitch: _canSwitchCuisine,
          onSwitch: _switchCuisine,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDeck(deck.options),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _flipping
                            ? null
                            : (_index + 1 >= deck.options.length
                                  ? _switchCuisine
                                  : _next),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: AppTheme.ink,
                          side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.12)),
                        ),
                        icon: Icon(
                          _index + 1 >= deck.options.length
                              ? Icons.casino_rounded
                              : Icons.refresh_rounded,
                          size: 17,
                        ),
                        label: Text(
                            _index + 1 >= deck.options.length ? '换菜系' : '换一家'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _flipping ? null : _confirm,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('就吃这个'),
                      ),
                    ),
                  ],
                ),
                if (_index + 1 >= deck.options.length) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '这个菜系翻完了，换一个菜系试试',
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 卡牌堆：最多三张，翻牌时当前卡飞出、下一张升起。
  Widget _buildDeck(List<Restaurant> options) {
    final current = options[_index];
    final hasNext = _index + 1 < options.length;
    final hasSecond = _index + 2 < options.length;

    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_flip.value);
        return SizedBox(
          width: restaurantCardWidth,
          height: restaurantCardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (hasSecond)
                Transform.translate(
                  offset: const Offset(0, 18),
                  child: Transform.scale(
                    scale: 0.88,
                    child: Opacity(
                      opacity: 0.7,
                      child: RestaurantCardView(restaurant: options[_index + 2]),
                    ),
                  ),
                ),
              if (hasNext)
                Transform.translate(
                  offset: Offset(0, 12 * (1 - t)),
                  child: Transform.scale(
                    scale: 0.92 + 0.08 * t,
                    child: RestaurantCardView(restaurant: options[_index + 1]),
                  ),
                ),
              Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(-1.1 * restaurantCardWidth * t, 0),
                  child: Transform.rotate(
                    angle: -0.35 * t,
                    child: RestaurantCardView(restaurant: current),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 顶部筛选胶囊：已选条件常驻，点击任意胶囊打开筛选面板。
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.cuisines,
    required this.onOpen,
  });

  final DineOutFilters filters;
  final List<DineCuisine> cuisines;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final names = cuisines
        .where(
          (cuisine) => filters.cuisineIds.contains(int.tryParse(cuisine.id)),
        )
        .map((cuisine) => cuisine.name)
        .toList();

    final chips = <Widget>[
      _Chip(
        icon: Icons.restaurant_menu_rounded,
        label: names.isEmpty
            ? '🎲 菜系自动'
            : names.length == 1
            ? names.first
            : '${names.first} +${names.length - 1}',
        selected: names.isNotEmpty,
        onTap: onOpen,
      ),
      _Chip(
        icon: Icons.payments_outlined,
        label: filters.maxCost == null ? '人均不限' : '¥${filters.maxCost} 以内',
        selected: filters.maxCost != null,
        onTap: onOpen,
      ),
      _Chip(
        icon: Icons.near_me_outlined,
        label: _radiusText(filters.radius),
        selected: filters.radius != 3000,
        onTap: onOpen,
      ),
      _Chip(
        icon: Icons.tune_rounded,
        label: filters.activeCount > 0 ? '筛选 ${filters.activeCount}' : '筛选',
        selected: filters.activeCount > 0,
        onTap: onOpen,
      ),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  static String _radiusText(int radius) {
    if (radius < 1000) return '$radius m 内';
    return '${(radius / 1000).toStringAsFixed(radius % 1000 == 0 ? 0 : 1)} km 内';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.persimmon.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.persimmon.withValues(alpha: 0.75)
                : AppTheme.ink.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: selected ? 0.08 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? AppTheme.persimmon : Colors.black45,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppTheme.persimmon : AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 菜系条：「今天吃 川菜 · 附近 12 家」+ 换菜系。
class _CuisineBar extends StatelessWidget {
  const _CuisineBar({
    required this.deck,
    required this.canSwitch,
    required this.onSwitch,
  });

  final RestaurantDeck deck;
  final bool canSwitch;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.persimmon, Color(0xFFE8552A)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.ramen_dining_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '今天吃 ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                    ),
                  ),
                  TextSpan(
                    text: deck.cuisineName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.persimmon,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canSwitch) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSwitch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.persimmon, Color(0xFFE8552A)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.persimmon.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎲', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      '换菜系',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
