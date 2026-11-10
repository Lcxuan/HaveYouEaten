import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/api/cuisine/cuisine_api.dart';
import 'package:have_you_eaten/api/cuisine/response/cuisine.dart';
import 'package:have_you_eaten/api/recipe/recipe_api.dart';
import 'package:have_you_eaten/api/recipe/response/recipe_draw_result.dart';
import 'package:have_you_eaten/api/record/record_api.dart';
import 'package:have_you_eaten/components/food_wheel.dart';
import 'package:have_you_eaten/components/shake_detector.dart';
import 'package:have_you_eaten/config/api_config.dart';
import 'package:have_you_eaten/store/auth_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/utils/error_util.dart';
import 'package:have_you_eaten/views/home/tabs/dine_out_tab.dart';
import 'package:have_you_eaten/views/home/widgets/draw_filter_sheet.dart';
import 'package:have_you_eaten/views/home/widgets/draw_result_sheet.dart';

/// 就餐模式：出去吃 / 在家吃。
enum _MealMode { out, home }

/// 餐段，编码与菜系 `mealPeriods` 一致。
enum _MealPeriod {
  breakfast(1, '早餐时间'),
  lunch(2, '午餐时间'),
  dinner(3, '晚餐时间'),
  night(4, '夜宵时间');

  const _MealPeriod(this.code, this.label);

  final int code;
  final String label;
}

/// 首页页签：日期问候、模式切换、快捷筛选与菜品抽签转盘
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key, this.onOpenSettings, this.isActive = true});

  /// 右上角齿轮
  final VoidCallback? onOpenSettings;

  /// 当前页签是否可见；底部切到其他页签时关闭摇一摇。
  final bool isActive;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> with WidgetsBindingObserver {
  static const _maxWheelSectors = 8;
  static const _defaultWheelLabels = [
    '家常菜',
    '川菜',
    '湘菜',
    '粤菜',
    '面食',
    '汤羹',
    '硬菜',
    '快手菜',
  ];

  final _wheelKey = GlobalKey<FoodWheelState>();
  DrawFilters _filters = const DrawFilters();

  /// 接口返回的启用菜系。
  List<Cuisine> _cuisines = const [];

  /// 当前扇区对应的餐段，用于判断是否需要重新筛选。
  _MealPeriod? _loadedPeriod;

  /// 本轮扇区文案；接口失败时用内置值。
  List<String> _baseWheelLabels = _defaultWheelLabels;
  List<String> _wheelLabels = _defaultWheelLabels;

  /// 本轮扇区对应的菜系；抽签时作为 cuisineIds 传给后端。
  List<Cuisine> _wheelCuisines = const [];
  _MealMode _mode = _MealMode.home;
  bool _drawing = false;

  /// 筛选或结果弹层是否打开；弹层期间摇一摇不触发。
  bool _sheetVisible = false;

  /// 定时检查餐段，跨时段后自动刷新轮盘菜系。
  Timer? _periodTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCuisines();
    _periodTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || _drawing) return;
      // 启动时接口失败会退回内置扇区，这里顺带重试拉取。
      if (_cuisines.isEmpty) {
        _loadCuisines();
      } else if (_loadedPeriod != _currentPeriod) {
        _rebuildWheel();
      } else {
        // 同一餐段内只刷新日期行，不重新抽样扇区。
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从后台回到前台时，可能已经跨餐段，也可能之前加载菜系失败。
    if (state != AppLifecycleState.resumed) return;
    if (_cuisines.isEmpty) {
      _loadCuisines();
    } else if (_loadedPeriod != _currentPeriod) {
      _rebuildWheel();
    }
  }

  @override
  void dispose() {
    _periodTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 当前餐段：05-10 早餐、10-15 午餐、15-21 晚餐，其余为夜宵。
  _MealPeriod get _currentPeriod {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 10) return _MealPeriod.breakfast;
    if (hour >= 10 && hour < 15) return _MealPeriod.lunch;
    if (hour >= 15 && hour < 21) return _MealPeriod.dinner;
    return _MealPeriod.night;
  }

  /// 拉取启用的菜系，按当前餐段筛选扇区；失败时保持内置扇区。
  Future<void> _loadCuisines() async {
    try {
      final cuisines = await CuisineApi.list();
      if (!mounted || cuisines.isEmpty) return;
      _cuisines = cuisines;
      _rebuildWheel();
    } catch (error) {
      debugPrint('加载菜系列表失败：$error');
    }
  }

  /// 按当前餐段筛选菜系并生成本轮扇区。
  ///
  /// 可用菜系不超过 8 个时全部展示；超过 8 个时随机抽 8 个，再按 sort 升序排列。
  void _rebuildWheel() {
    if (!mounted) return;
    final picked = _pickWheelCuisines();
    setState(() {
      _loadedPeriod = _currentPeriod;
      _wheelCuisines = picked;
      _baseWheelLabels = picked.isEmpty
          ? _defaultWheelLabels
          : picked.map((cuisine) => cuisine.name).toList();
      _wheelLabels = _baseWheelLabels;
    });
  }

  /// 按当前餐段筛选菜系，再按扇区数量规则挑选。
  ///
  /// 可用菜系不超过 8 个时全部展示；超过 8 个时随机抽 8 个，再按 sort 升序排列。
  List<Cuisine> _pickWheelCuisines() {
    final period = _currentPeriod.code;
    final visible =
        _cuisines
            .where(
              (cuisine) =>
                  cuisine.mealPeriods.isEmpty ||
                  cuisine.mealPeriods.contains(period),
            )
            .toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));
    if (visible.isEmpty) {
      return const [];
    }
    if (visible.length <= _maxWheelSectors) {
      return visible;
    }
    return ([...visible]..shuffle()).take(_maxWheelSectors).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
  }

  Future<void> _draw() async {
    if (_drawing) return;
    // 抽签接口需登录访问，未登录先提示去「设置」页登录。
    if (!ref.read(authProvider).loggedIn) {
      _showMessage('请先在底部「设置」页登录后再开抽');
      return;
    }
    // 菜系列表未加载成功时先重试，避免一直显示内置扇区。
    if (_cuisines.isEmpty) await _loadCuisines();
    if (!mounted) return;
    // 休眠期间可能跨餐段，开抽前按当前餐段重新筛选。
    if (_loadedPeriod != _currentPeriod || _cuisines.isEmpty) _rebuildWheel();

    // 把当前轮盘上的菜系作为筛选条件，保证抽中菜品一定落在扇区内。
    final cuisineIds = _wheelCuisines
        .map((cuisine) => int.tryParse(cuisine.id))
        .whereType<int>()
        .toList();

    setState(() => _drawing = true);
    // 请求发出后先预热慢转，结果回来后无缝减速落到中奖扇区。
    _wheelKey.currentState?.startIdle();

    RecipeDrawResult? result;
    Object? error;
    try {
      result = await RecipeApi.draw(
        cuisineIds: cuisineIds,
        tastes: _filters.tastes.toList(),
        maxCookMinutes: _filters.maxCookMinutes,
        difficulty: _filters.difficulty,
      );
    } catch (e) {
      error = e;
    }
    if (!mounted) return;

    if (result == null) {
      _wheelKey.currentState?.stopIdle();
      setState(() => _drawing = false);
      _showMessage(friendlyError(error));
      return;
    }

    // 从菜系扇区复制；抽中菜系不在其中时替换末位扇区，保证指针落点与结果一致。
    final labels = [..._baseWheelLabels];
    final cuisine = result.recipe.primaryCuisine.isEmpty
        ? result.recipe.name
        : result.recipe.primaryCuisine;
    var winnerIndex = labels.indexOf(cuisine);
    if (winnerIndex < 0) {
      winnerIndex = labels.length - 1;
      labels[winnerIndex] = cuisine;
    }
    setState(() => _wheelLabels = labels);

    // 先拿到结果再转动，指针最终停在抽中菜品所在扇区。
    await _wheelKey.currentState?.spinTo(winnerIndex, count: labels.length);
    if (!mounted) return;

    setState(() => _drawing = false);
    await _showResult(result);
  }

  Future<void> _showResult(RecipeDrawResult result) async {
    _sheetVisible = true;
    final again = await showDrawResultSheet(
      context,
      result: result,
      loggedIn: ref.read(authProvider).loggedIn,
      onRecord: () => _record(result.recipe.id),
    );
    _sheetVisible = false;
    if (!mounted) return;
    // 弹层关闭后再重新抽样，避免用户看到扇区在结果页背后变化。
    _rebuildWheel();
    if (again) await _draw();
  }

  Future<bool> _record(String recipeId) async {
    try {
      await RecordApi.create(recipeId: recipeId);
      if (mounted) _showMessage('已记一笔');
      return true;
    } catch (error) {
      if (mounted) _showMessage(friendlyError(error));
      return false;
    }
  }

  Future<void> _openFilters() async {
    _sheetVisible = true;
    final result = await showDrawFilterSheet(context, _filters);
    _sheetVisible = false;
    if (result != null && mounted) setState(() => _filters = result);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _dateLine {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]} · ${_currentPeriod.label}';
  }

  @override
  Widget build(BuildContext context) {
    final wheelSize = (MediaQuery.sizeOf(context).width - 56)
        .clamp(220.0, 300.0)
        .toDouble();
    final accent = _mode == _MealMode.out
        ? AppTheme.persimmon
        : AppTheme.scallion;

    return ShakeDetector(
      enabled:
          widget.isActive &&
          _mode == _MealMode.home &&
          !_drawing &&
          !_sheetVisible,
      onShake: _draw,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.persimmon,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _drawing ? '手气决定！' : ApiConfig.appName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _drawing ? '正在为你抽签…' : _dateLine,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onOpenSettings,
                    icon: const Icon(Icons.settings_outlined),
                    color: AppTheme.ink,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ModeSwitch(
                mode: _mode,
                onChanged: (mode) {
                  if (_drawing) return;
                  setState(() => _mode = mode);
                },
              ),
              if (_mode == _MealMode.out) ...[
                const SizedBox(height: 12),
                const Expanded(child: DineOutTab()),
              ] else ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickChip(
                      label: '微辣',
                      selected: _filters.tastes.contains('微辣'),
                      onTap: _drawing
                          ? null
                          : () => setState(
                              () => _filters = _filters.toggleTaste('微辣'),
                            ),
                    ),
                    _QuickChip(
                      label: '30 分钟内',
                      selected: _filters.maxCookMinutes == 30,
                      onTap: _drawing
                          ? null
                          : () => setState(
                              () => _filters = _filters.withMaxCookMinutes(
                                _filters.maxCookMinutes == 30 ? null : 30,
                              ),
                            ),
                    ),
                    _QuickChip(
                      label: '简单',
                      selected: _filters.difficulty == 1,
                      onTap: _drawing
                          ? null
                          : () => setState(
                              () => _filters = _filters.withDifficulty(
                                _filters.difficulty == 1 ? null : 1,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _QuickChip(
                    label: '筛选',
                    icon: Icons.keyboard_arrow_down_rounded,
                    selected: false,
                    neutral: true,
                    onTap: _drawing ? null : _openFilters,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FoodWheel(
                          key: _wheelKey,
                          onTap: _draw,
                          size: wheelSize,
                          accent: accent,
                          labels: _wheelLabels,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _drawing
                              ? '正在从候选池里抽…'
                              : _filters.activeCount > 0
                              ? '已按偏好过滤候选池 · 摇一摇也能开抽'
                              : 'shake 摇一摇手机也可以开抽',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 出去吃 / 在家吃 分段切换。
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final _MealMode mode;
  final ValueChanged<_MealMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: '在家吃',
              icon: Icons.restaurant_rounded,
              selected: mode == _MealMode.home,
              accent: AppTheme.scallion,
              onTap: () => onChanged(_MealMode.home),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: '出去吃',
              icon: Icons.rice_bowl_rounded,
              selected: mode == _MealMode.out,
              accent: AppTheme.persimmon,
              onTap: () => onChanged(_MealMode.out),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : Colors.black45,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 快捷筛选胶囊：默认橙描边，筛选按钮为中性描边。
class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.neutral = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final accent = neutral ? Colors.black54 : AppTheme.persimmon;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent
                : accent.withValues(alpha: neutral ? 0.35 : 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: accent,
              ),
            ),
            if (icon != null) ...[Icon(icon, size: 15, color: accent)],
          ],
        ),
      ),
    );
  }
}
