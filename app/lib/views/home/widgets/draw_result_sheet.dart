import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/api/recipe/response/recipe_draw_result.dart';
import 'package:have_you_eaten/api/recipe/response/recipe_summary.dart';
import 'package:have_you_eaten/styles/app_theme.dart';

/// 抽中结果的底部卡片；返回 true 表示用户点了再来一次。
Future<bool> showDrawResultSheet(
  BuildContext context, {
  required RecipeDrawResult result,
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
    builder: (context) => _DrawResultSheet(
      result: result,
      loggedIn: loggedIn,
      onRecord: onRecord,
    ),
  );
  return again ?? false;
}

class _DrawResultSheet extends StatefulWidget {
  const _DrawResultSheet({
    required this.result,
    required this.loggedIn,
    required this.onRecord,
  });

  final RecipeDrawResult result;
  final bool loggedIn;
  final Future<bool> Function() onRecord;

  @override
  State<_DrawResultSheet> createState() => _DrawResultSheetState();
}

class _DrawResultSheetState extends State<_DrawResultSheet> {
  bool _saving = false;
  bool _needLogin = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.result.recipe;

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
          Row(
            children: [
              const Text(
                '抽中啦',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.chili,
                ),
              ),
              const Spacer(),
              Text(
                '候选池 ${widget.result.poolSize} 道',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RecipeCard(recipe: recipe),
          if (recipe.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              recipe.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
          ],
          if (_needLogin) ...[
            const SizedBox(height: 10),
            const Text(
              '请先在底部「设置」页登录后再记一笔',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppTheme.chili),
            ),
          ],
          const SizedBox(height: 20),
          // 主操作：记一笔
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
                child: FilledButton(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.pop(context);
                    router.push('/recipe/${recipe.id}');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.scallion,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('查看详情'),
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
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 84,
              height: 84,
              child: _RecipeImage(url: recipe.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (recipe.cookMinutes != null)
                      _Meta(
                        icon: Icons.schedule_rounded,
                        text: '${recipe.cookMinutes} 分钟',
                      ),
                    if (recipe.difficulty != null)
                      _Meta(
                        icon: Icons.local_fire_department_rounded,
                        text: _difficultyText(recipe.difficulty!),
                      ),
                    if (recipe.cuisines.isNotEmpty)
                      _Meta(
                        icon: Icons.restaurant_menu_rounded,
                        text: recipe.cuisines.join(' · '),
                      ),
                  ],
                ),
                if (recipe.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final tag in recipe.tags.take(4))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.yolk.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFB4740A),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (recipe.isAiGenerated) ...[
                  const SizedBox(height: 6),
                  const _AiBadge(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _difficultyText(int difficulty) {
    return switch (difficulty) {
      1 => '简单',
      2 => '中等',
      3 => '困难',
      _ => '难度 $difficulty',
    };
  }
}

class _RecipeImage extends StatelessWidget {
  const _RecipeImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _ImageFallback();
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.paper,
      alignment: Alignment.center,
      child: const Icon(
        Icons.rice_bowl_rounded,
        size: 34,
        color: AppTheme.persimmon,
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.black45),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.black45),
          SizedBox(width: 3),
          Text(
            'AI 生成内容',
            style: TextStyle(fontSize: 9.5, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
