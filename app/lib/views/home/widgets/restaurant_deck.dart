import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:have_you_eaten/api/restaurant/response/restaurant.dart';
import 'package:have_you_eaten/styles/app_theme.dart';

/// 卡牌尺寸，与原型保持一致。
const double restaurantCardWidth = 252;
const double restaurantCardHeight = 264;

/// 空闲态整叠牌背，带轻微错位与倾斜。
class IdleCardStack extends StatelessWidget {
  const IdleCardStack({super.key, this.loading = false, this.message});

  final bool loading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: restaurantCardWidth,
      height: restaurantCardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-10, 10),
            child: Transform.rotate(
              angle: -0.06,
              child: const Opacity(
                opacity: 0.55,
                child: RestaurantCardBack(),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(10, 5),
            child: Transform.rotate(
              angle: 0.05,
              child: const Opacity(
                opacity: 0.75,
                child: RestaurantCardBack(),
              ),
            ),
          ),
          RestaurantCardBack(loading: loading, message: message),
        ],
      ),
    );
  }
}

/// 牌背：柿橙渐变 + 斜纹 + 🍚「吃了吗」。
class RestaurantCardBack extends StatelessWidget {
  const RestaurantCardBack({super.key, this.loading = false, this.message});

  final bool loading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: restaurantCardWidth,
      height: restaurantCardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.persimmon, Color(0xFFE8552A)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _StripePainter(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍚', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 10),
                  const Text(
                    '吃了吗',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message ??
                        (loading ? '正在抽菜系 · 找附近的店…' : '先抽菜系 · 再翻附近的店'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  if (loading) ...[
                    const SizedBox(height: 14),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 10;
    for (double x = -size.height; x < size.width; x += 26) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 一张餐厅卡：封面、店名、评分 / 人均、标签、地址与距离。
class RestaurantCardView extends StatelessWidget {
  const RestaurantCardView({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: restaurantCardWidth,
      height: restaurantCardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: _Cover(photo: restaurant.photo),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      if (restaurant.rating != null)
                        _Meta(
                          icon: Icons.star_rounded,
                          text: restaurant.rating!.toStringAsFixed(1),
                          color: AppTheme.yolk,
                        ),
                      if (restaurant.costText.isNotEmpty)
                        _Meta(
                          icon: Icons.payments_rounded,
                          text: restaurant.costText,
                        ),
                    ],
                  ),
                  if (restaurant.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final tag in restaurant.tags.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.persimmon.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.persimmon,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 13,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          restaurant.distanceText.isEmpty
                              ? restaurant.address
                              : '${restaurant.address} · 距你 ${restaurant.distanceText}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.photo});

  final String photo;

  @override
  Widget build(BuildContext context) {
    if (photo.isEmpty) return const _CoverFallback();
    return Image.network(
      photo,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _CoverFallback(),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3C7), Color(0xFFFFC9A8)],
        ),
      ),
      alignment: Alignment.center,
      child: const Text('🍚', style: TextStyle(fontSize: 40)),
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

/// 可下拉的绳子：向下拉过阈值触发开始，松手弹回。
class PullCord extends StatefulWidget {
  const PullCord({super.key, required this.onTriggered, this.enabled = true});

  final VoidCallback onTriggered;
  final bool enabled;

  @override
  State<PullCord> createState() => _PullCordState();
}

class _PullCordState extends State<PullCord> {
  static const _baseHeight = 78.0;
  static const _maxPull = 110.0;
  static const _threshold = 64.0;

  double _pull = 0;
  bool _armed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: widget.enabled ? _onDrag : null,
      onVerticalDragEnd: widget.enabled ? _onDragEnd : null,
      child: SizedBox(
        width: 90,
        height: _baseHeight + _pull,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _CordPainter(pull: _pull)),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppTheme.persimmon, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.persimmon.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDrag(DragUpdateDetails details) {
    final next = (_pull + details.delta.dy).clamp(0.0, _maxPull).toDouble();
    if (next >= _threshold && !_armed) {
      _armed = true;
      HapticFeedback.lightImpact();
    }
    if (next != _pull) setState(() => _pull = next);
  }

  void _onDragEnd(DragEndDetails details) {
    final triggered = _pull >= _threshold;
    setState(() {
      _pull = 0;
      _armed = false;
    });
    if (triggered) widget.onTriggered();
  }
}

class _CordPainter extends CustomPainter {
  const _CordPainter({required this.pull});

  final double pull;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD9B38C)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final top = Offset(size.width / 2, 0);
    final bottom = Offset(size.width / 2, size.height - 14);
    final path = Path()..moveTo(top.dx, top.dy);
    // 轻微弧度，拉得越长越直，暗示绳子张力
    final bend = 6 - pull / 30;
    path.quadraticBezierTo(
      top.dx + bend,
      (top.dy + bottom.dy) / 2,
      bottom.dx,
      bottom.dy,
    );
    canvas.drawPath(path, paint);

    // 顶部锚点
    canvas.drawCircle(top, 3, Paint()..color = const Color(0xFFC99B70));
  }

  @override
  bool shouldRepaint(covariant _CordPainter oldDelegate) =>
      oldDelegate.pull != pull;
}
