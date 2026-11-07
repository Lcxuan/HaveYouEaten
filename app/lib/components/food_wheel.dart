import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'package:have_you_eaten/styles/app_theme.dart';

const _defaultWheelLabels = ['火锅', '烧烤', '日料', '麻辣烫', '汉堡', '面条', '炒菜', '饺子'];

/// 菜品转盘
class FoodWheel extends StatefulWidget {
  const FoodWheel({
    super.key,
    required this.onTap,
    this.size = 268,
    this.accent = AppTheme.persimmon,
    this.labels = _defaultWheelLabels,
  });

  /// 点击中心按钮的回调。
  final VoidCallback onTap;

  /// 转盘直径。
  final double size;

  /// 中心按钮配色（在家吃为葱绿，出去吃为柿橙）。
  final Color accent;

  /// 各扇区文案，数量决定扇区数。
  final List<String> labels;

  @override
  FoodWheelState createState() => FoodWheelState();
}

class FoodWheelState extends State<FoodWheel> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  final _random = math.Random();

  /// 等待接口返回时的匀速预热转动，结果回来后再减速落位。
  late final AnimationController _idleController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  /// 静止时的累计角度；预热或落点动画期间由控制器相位推导当前角度。
  double _angle = 0;
  double _begin = 0;
  double _end = 0;

  /// 预热转动开始时的基准角度。
  double _idleBase = 0;

  /// 当前视觉角度：预热期间读相位，落点动画期间读补间值。
  double get _currentAngle {
    if (_idleController.isAnimating) {
      return _idleBase + _idleController.value * math.pi * 2;
    }
    if (_controller.isAnimating) {
      final value = Curves.easeOutCubic.transform(_controller.value);
      return _begin + (_end - _begin) * value;
    }
    return _angle;
  }

  /// 是否正在旋转（预热或落点动画都算）。
  bool get spinning => _controller.isAnimating || _idleController.isAnimating;

  /// 开始预热：请求发出后立即慢转，避免点击后转盘静止等待。
  void startIdle() {
    if (spinning) return;
    _idleBase = _angle;
    // 上一轮预热暂停时相位不为 0，直接 repeat 会从旧相位起跳，需先归零。
    _idleController.value = 0;
    _idleController.repeat();
  }

  /// 停止预热，并把当前相位换算成静态角度。
  void stopIdle() {
    if (!_idleController.isAnimating) return;
    _angle = _normalize(_idleBase + _idleController.value * math.pi * 2);
    _idleController.stop();
  }

  /// 旋转约 4 圈后缓慢停在随机位置。
  Future<void> spin() async {
    if (_controller.isAnimating) return;
    stopIdle();
    _begin = _angle;
    _end = _begin + math.pi * 8 + _random.nextDouble() * math.pi * 2;
    await _controller.forward(from: 0);
    _angle = _normalize(_end);
  }

  /// 旋转约 4 圈后让指针停在 [index] 对应扇区的中心。
  ///
  /// 指针固定在顶部；扇区中心角为 `(-90° + (index + 0.5) * sweep)`，
  /// 因此需要额外旋转 `-(index + 0.5) * sweep` 才能对齐。
  /// [count] 用于扇区数量刚变化、widget 尚未重建的场景。
  Future<void> spinTo(int index, {int? count}) async {
    final total = count ?? widget.labels.length;
    if (total == 0 || _controller.isAnimating) return;
    stopIdle();
    final sweep = math.pi * 2 / total;
    final safeIndex = index.clamp(0, total - 1);
    final target = _normalize(-(safeIndex + 0.5) * sweep);
    var delta = target - _normalize(_angle);
    if (delta < 0) delta += math.pi * 2;

    _begin = _angle;
    _end = _angle + math.pi * 8 + delta;
    await _controller.forward(from: 0);
    _angle = _normalize(_end);
  }

  double _normalize(double value) {
    final twoPi = math.pi * 2;
    final result = value % twoPi;
    return result < 0 ? result + twoPi : result;
  }

  @override
  void dispose() {
    _controller.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return SizedBox(
      width: size,
      height: size + 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.ink.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_controller, _idleController]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _currentAngle,
                      child: child,
                    );
                  },
                  child: CustomPaint(
                    painter: _WheelPainter(widget.labels),
                    size: Size(size, size),
                  ),
                ),
              ),
            ),
          ),
          // 指针放在轮盘之后绘制，避免被轮盘盖住。
          Align(
            alignment: Alignment.topCenter,
            child: CustomPaint(
              size: const Size(26, 22),
              painter: _PointerPainter(color: Color(0xFFB03A2E)),
            ),
          ),
          Positioned(
            top: 10 + size / 2 - 44,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (!spinning) widget.onTap();
                },
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accent,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            spinning ? '···' : '开抽',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            spinning ? '抽签中' : 'GO EAT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部指针：倒三角。
class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 扇区填充与文字，扇区数量随候选菜系变化。
class _WheelPainter extends CustomPainter {
  const _WheelPainter(this.labels);

  final List<String> labels;

  static const _colors = [
    Color(0xFFFFC53D),
    Color(0xFFFF9440),
    Color(0xFFFF6B35),
    Color(0xFFE8503A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final count = labels.length;
    if (count == 0) return;

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = math.pi * 2 / count;
    const startOffset = -math.pi / 2;

    final fill = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      fill.color = _colors[i % _colors.length];
      canvas.drawArc(rect, startOffset + i * sweep, sweep, true, fill);
    }

    // 白色外圈。
    canvas.drawCircle(
      center,
      radius - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = Colors.white,
    );

    final fontSize = count <= 4
        ? 16.0
        : count <= 6
        ? 14.5
        : 13.0;

    // 菜系名沿扇区中心半径摆放，并保持水平可读。
    for (var i = 0; i < count; i++) {
      final midAngle = startOffset + (i + 0.5) * sweep;
      final direction = Offset(math.cos(midAngle), math.sin(midAngle));
      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: const [Shadow(color: Color(0x33000000), blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelCenter = center + direction * (radius * 0.66);
      labelPainter.paint(
        canvas,
        labelCenter - Offset(labelPainter.width / 2, labelPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      !listEquals(oldDelegate.labels, labels);
}
