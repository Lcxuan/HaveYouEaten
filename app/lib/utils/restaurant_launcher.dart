import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'package:have_you_eaten/api/restaurant/response/restaurant.dart';

/// 唤起高德导航；未安装高德时回退到网页版。
class RestaurantLauncher {
  RestaurantLauncher._();

  /// 导航到餐厅，返回是否成功打开。
  static Future<bool> navigate(Restaurant restaurant) async {
    final position = _position(restaurant);
    if (position == null) return false;
    final (lng, lat) = position;
    final name = Uri.encodeComponent(restaurant.name);

    final appUri = Platform.isIOS
        ? Uri.parse(
            'iosamap://path?sourceApplication=hye&dname=$name'
            '&dlat=$lat&dlon=$lng&dev=0&t=0',
          )
        : Uri.parse(
            'androidamap://route?sourceApplication=hye'
            '&dlat=$lat&dlon=$lng&dname=$name&dev=0&t=0',
          );

    if (await canLaunchUrl(appUri)) {
      return launchUrl(appUri, mode: LaunchMode.externalApplication);
    }
    final webUri = Uri.parse(
      'https://uri.amap.com/marker?position=$lng,$lat&name=$name',
    );
    try {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// 导航坐标：入口坐标优先，缺失时用 POI 坐标。
  static (double, double)? _position(Restaurant restaurant) {
    if (restaurant.entrLocation.contains(',')) {
      final parts = restaurant.entrLocation.split(',');
      final lng = double.tryParse(parts[0].trim());
      final lat = double.tryParse(parts[1].trim());
      if (lng != null && lat != null) return (lng, lat);
    }
    if (restaurant.lng != null && restaurant.lat != null) {
      return (restaurant.lng!, restaurant.lat!);
    }
    return null;
  }
}
