/// 出去吃：一家餐厅。
class Restaurant {
  const Restaurant({
    required this.poiId,
    required this.name,
    this.address = '',
    this.distance,
    this.cost,
    this.rating,
    this.typecode = '',
    this.tags = const [],
    this.lng,
    this.lat,
    this.tel = '',
    this.openTime = '',
    this.entrLocation = '',
    this.photo = '',
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      poiId: json['poiId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      distance: _toInt(json['distance']),
      cost: _toDouble(json['cost']),
      rating: _toDouble(json['rating']),
      typecode: json['typecode']?.toString() ?? '',
      tags: _toTags(json['tags']),
      lng: _toDouble(json['lng']),
      lat: _toDouble(json['lat']),
      tel: json['tel']?.toString() ?? '',
      openTime: json['openTime']?.toString() ?? '',
      entrLocation: json['entrLocation']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
    );
  }

  final String poiId;
  final String name;
  final String address;

  /// 距离（米），可能为空。
  final int? distance;

  /// 人均（元），可能为空。
  final double? cost;

  /// 评分，可能为空。
  final double? rating;

  final String typecode;
  final List<String> tags;
  final double? lng;
  final double? lat;
  final String tel;
  final String openTime;

  /// 入口坐标 lng,lat，导航优先使用。
  final String entrLocation;
  final String photo;

  /// 距离文案：不足 1km 显示米，超过显示公里。
  String get distanceText {
    final value = distance;
    if (value == null) return '';
    if (value < 1000) return '$value m';
    return '${(value / 1000).toStringAsFixed(1)} km';
  }

  /// 人均文案。
  String get costText {
    final value = cost;
    if (value == null) return '';
    return '¥${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}/人';
  }

  /// 导航坐标：优先入口坐标，否则用 POI 坐标。
  String get naviPosition =>
      entrLocation.isNotEmpty ? entrLocation : '${lng ?? ''},${lat ?? ''}';

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String> _toTags(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
