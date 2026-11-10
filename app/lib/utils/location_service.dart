import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一次定位的结果。
class AppLocation {
  const AppLocation({
    required this.longitude,
    required this.latitude,
    required this.accuracy,
    this.cachedAt,
  });

  final double longitude;
  final double latitude;

  /// 精度半径（米）。Android 只授权「大致位置」时会超过 1000。
  final double accuracy;

  /// 非空表示来自本地缓存，值是缓存写入时间。
  final DateTime? cachedAt;

  bool get fromCache => cachedAt != null;

  /// 精度过差，不足以按 1km 半径找店。
  bool get isApproximate => accuracy > 1000;
}

/// 设备定位：权限申请、超时控制，失败时依次回退到系统末次位置与本地缓存。
///
/// 坐标系随平台而定：iOS 国内返回 GCJ-02，可直接给高德用；Android 可能是
/// WGS-84，是否存在偏移需实机对照高德确认，偏移处理放在服务端。
class LocationService {
  LocationService._();

  static const _lngKey = 'location_lng';
  static const _latKey = 'location_lat';
  static const _accuracyKey = 'location_accuracy';
  static const _timeKey = 'location_time';

  /// 室内 GPS 容易一直不返回，超过该时长即放弃实时定位。
  static const _timeout = Duration(seconds: 8);

  /// 定位：实时 → 系统末次位置 → 本地缓存，都没有返回 null。
  static Future<AppLocation?> locate() async {
    final fresh = await _current();
    if (fresh != null) {
      await _writeCache(fresh);
      return fresh;
    }

    final lastKnown = await _lastKnown();
    if (lastKnown != null) {
      await _writeCache(lastKnown);
      return lastKnown;
    }

    return cached();
  }

  /// 只读本地缓存，用于冷启动时先用上次位置发牌，避免首页空等。
  static Future<AppLocation?> cached() async {
    final prefs = await SharedPreferences.getInstance();
    final longitude = prefs.getDouble(_lngKey);
    final latitude = prefs.getDouble(_latKey);
    if (longitude == null || latitude == null) return null;

    final millis = prefs.getInt(_timeKey);
    return AppLocation(
      longitude: longitude,
      latitude: latitude,
      accuracy: prefs.getDouble(_accuracyKey) ?? 0,
      cachedAt: millis == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }

  /// 定位被永久拒绝时，跳系统设置让用户手动打开。
  static Future<void> openSettings() => Geolocator.openAppSettings();

  static Future<AppLocation?> _current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );
      return _fromPosition(position);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<AppLocation?> _lastKnown() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      return position == null ? null : _fromPosition(position);
    } catch (_) {
      return null;
    }
  }

  static AppLocation _fromPosition(Position position) {
    return AppLocation(
      longitude: position.longitude,
      latitude: position.latitude,
      accuracy: position.accuracy,
    );
  }

  static Future<void> _writeCache(AppLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lngKey, location.longitude);
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_accuracyKey, location.accuracy);
    await prefs.setInt(_timeKey, DateTime.now().millisecondsSinceEpoch);
  }
}
