import 'package:have_you_eaten/api/favorite/response/favorite_item.dart';

/// 收藏分页结果。
class FavoritePage {
  const FavoritePage({required this.items, required this.total});

  const FavoritePage.empty() : items = const [], total = 0;

  final List<FavoriteItem> items;
  final int total;
}
