import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 摇一摇手势：监听去掉重力后的加速度，合量超过阈值时触发一次回调。
///
/// 一次摇动会连续上报几十个事件
/// 内部用 [cooldown] 冷却；
/// [enabled] 为 false 时保持订阅但不触发，用于页签不可见、正在抽签或已有弹层时静默。
class ShakeDetector extends StatefulWidget {
  const ShakeDetector({
    super.key,
    required this.child,
    required this.onShake,
    this.enabled = true,
    this.threshold = 12,
    this.cooldown = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final VoidCallback onShake;
  final bool enabled;

  /// 加速度合量阈值（m/s²）。去掉重力后，日常晃动约 5~10。
  final double threshold;

  /// 两次触发之间的最小间隔。
  final Duration cooldown;

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  StreamSubscription<UserAccelerometerEvent>? _subscription;

  DateTime _lastTriggeredAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _subscription = userAccelerometerEventStream().listen(
      _onEvent,
      onError: (Object error) => debugPrint('摇一摇监听失败：$error'),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onEvent(UserAccelerometerEvent event) {
    if (!widget.enabled) return;
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < widget.threshold) return;

    final now = DateTime.now();
    if (now.difference(_lastTriggeredAt) < widget.cooldown) return;
    _lastTriggeredAt = now;
    widget.onShake();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
