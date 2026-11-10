import 'package:flutter/material.dart';

import 'package:have_you_eaten/api/restaurant/response/restaurant.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/utils/restaurant_launcher.dart';

/// 餐厅确认弹层；返回 true 表示用户点了「再来一次」。
Future<bool> showDineOutResultSheet(
  BuildContext context, {
  required Restaurant restaurant,
  required bool loggedIn,
  required Future<bool> Function() onRecord,
}) async {
  final again = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppTheme.paper,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => _DineOutResultSheet(
      restaurant: restaurant,
      loggedIn: loggedIn,
      onRecord: onRecord,
    ),
  );
  return again ?? false;
}

class _DineOutResultSheet extends StatefulWidget {
  const _DineOutResultSheet({
    required this.restaurant,
    required this.loggedIn,
    required this.onRecord,
  });

  final Restaurant restaurant;
  final bool loggedIn;
  final Future<bool> Function() onRecord;

  @override
  State<_DineOutResultSheet> createState() => _DineOutResultSheetState();
}

class _DineOutResultSheetState extends State<_DineOutResultSheet> {
  bool _saving = false;
  bool _needLogin = false;

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2D4C0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '就吃这个',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          _RestaurantSummary(restaurant: restaurant),
          if (_needLogin) ...[
            const SizedBox(height: 10),
            const Text(
              '请先在底部「设置」页登录后再记一笔',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppTheme.chili),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _record,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('就吃这个，记一笔'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.pop(context, true),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    foregroundColor: AppTheme.ink,
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                  ),
                  child: const Text('再来一次'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _navigate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.scallion,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 17),
                  label: const Text('导航去这里'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _record() async {
    if (!widget.loggedIn) {
      setState(() => _needLogin = true);
      return;
    }
    setState(() => _saving = true);
    final saved = await widget.onRecord();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.pop(context);
  }

  Future<void> _navigate() async {
    final opened = await RestaurantLauncher.navigate(widget.restaurant);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('无法打开导航，请稍后重试')));
    }
  }
}

class _RestaurantSummary extends StatelessWidget {
  const _RestaurantSummary({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
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
                _Meta(icon: Icons.payments_rounded, text: restaurant.costText),
              if (restaurant.distanceText.isNotEmpty)
                _Meta(
                  icon: Icons.near_me_rounded,
                  text: '距你 ${restaurant.distanceText}',
                ),
            ],
          ),
          if (restaurant.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final tag in restaurant.tags.take(4))
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
                        fontSize: 10.5,
                        color: AppTheme.persimmon,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (restaurant.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: Colors.black45,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    restaurant.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
