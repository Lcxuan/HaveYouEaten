import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:have_you_eaten/api/blacklist/blacklist_api.dart';
import 'package:have_you_eaten/api/favorite/favorite_api.dart';
import 'package:have_you_eaten/api/recipe/recipe_api.dart';
import 'package:have_you_eaten/api/recipe/response/recipe_detail.dart';
import 'package:have_you_eaten/store/auth_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/utils/error_util.dart';

/// 菜谱详情页：封面、基础信息、食材清单与做法步骤。
class RecipeDetailView extends ConsumerStatefulWidget {
  const RecipeDetailView({required this.id, super.key});

  final String id;

  @override
  ConsumerState<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends ConsumerState<RecipeDetailView> {
  RecipeDetail? _detail;
  String? _error;
  bool _favorited = false;
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final detail = await RecipeApi.detail(widget.id);
      if (!mounted) return;
      setState(() => _detail = detail);
      await _loadFavoriteStatus();
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    }
  }

  Future<void> _loadFavoriteStatus() async {
    if (!ref.read(authProvider).loggedIn) return;
    try {
      final favorited = await FavoriteApi.status(
        targetType: 'recipe',
        targetId: widget.id,
      );
      if (mounted) setState(() => _favorited = favorited);
    } catch (error) {
      debugPrint('加载收藏状态失败：$error');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    if (!ref.read(authProvider).loggedIn) {
      _showMessage('请先在底部「设置」页登录后再收藏');
      return;
    }
    final detail = _detail;
    if (detail == null) return;

    setState(() => _favoriteBusy = true);
    try {
      if (_favorited) {
        await FavoriteApi.remove(targetType: 'recipe', targetId: widget.id);
      } else {
        await FavoriteApi.add(
          targetType: 'recipe',
          targetId: widget.id,
          name: detail.summary.name,
        );
      }
      if (!mounted) return;
      setState(() => _favorited = !_favorited);
      _showMessage(_favorited ? '已收藏' : '已取消收藏');
    } catch (error) {
      if (mounted) _showMessage(friendlyError(error));
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _blacklistRecipe() async {
    final detail = _detail;
    if (detail == null) return;
    if (!ref.read(authProvider).loggedIn) {
      _showMessage('请先在底部「设置」页登录后再操作');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('不再推荐'),
        content: Text('确定不再推荐「${detail.summary.name}」吗？之后抽签不会抽到它。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.chili),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await BlacklistApi.add(
        scope: 'recipe',
        targetValue: widget.id,
        remark: detail.summary.name,
      );
      if (mounted) _showMessage('已加入黑名单，之后不会再抽到这道菜');
    } catch (error) {
      if (mounted) _showMessage(friendlyError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.summary.name ?? '菜谱详情'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: detail == null ? null : _toggleFavorite,
            tooltip: _favorited ? '取消收藏' : '收藏',
            icon: Icon(
              _favorited ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _favorited ? AppTheme.yolk : null,
            ),
          ),
          PopupMenuButton<String>(
            enabled: detail != null,
            tooltip: '更多',
            onSelected: (value) {
              if (value == 'blacklist') _blacklistRecipe();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'blacklist',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('不再推荐这道菜'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: detail == null
          ? _buildPlaceholder()
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              children: [
                _Cover(detail: detail),
                const SizedBox(height: 14),
                Text(
                  detail.summary.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                if (detail.summary.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail.summary.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                      height: 1.7,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _MetaRow(detail: detail),
                const SizedBox(height: 16),
                if (detail.ingredients.isNotEmpty)
                  _Panel(
                    title: '食材清单',
                    child: Column(
                      children: [
                        for (final item in detail.ingredients)
                          _IngredientRow(ingredient: item),
                      ],
                    ),
                  ),
                if (detail.steps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Panel(
                    title: '做法步骤',
                    child: Column(
                      children: [
                        for (final step in detail.steps)
                          _StepRow(step: step),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildPlaceholder() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _load, child: const Text('重新加载')),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

/// 顶部封面：无图或加载失败时用底图兜底。
class _Cover extends StatelessWidget {
  const _Cover({required this.detail});

  final RecipeDetail detail;

  @override
  Widget build(BuildContext context) {
    final url = detail.summary.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isEmpty)
              const _CoverFallback()
            else
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _CoverFallback(),
              ),
            if (detail.summary.isAiGenerated)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 11,
                        color: Colors.black45,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'AI 生成内容',
                        style: TextStyle(fontSize: 9.5, color: Colors.black45),
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
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.paper,
      alignment: Alignment.center,
      child: const Icon(
        Icons.rice_bowl_rounded,
        size: 48,
        color: AppTheme.persimmon,
      ),
    );
  }
}

/// 时长 / 难度 / 菜系 三个胶囊。
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.detail});

  final RecipeDetail detail;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        if (summary.cookMinutes != null)
          _MetaChip(
            icon: Icons.schedule_rounded,
            text: '${summary.cookMinutes} 分钟',
          ),
        if (summary.difficulty != null)
          _MetaChip(
            icon: Icons.local_fire_department_rounded,
            text: _difficultyText(summary.difficulty!),
          ),
        if (summary.cuisines.isNotEmpty)
          _MetaChip(
            icon: Icons.restaurant_menu_rounded,
            text: summary.cuisines.join(' · '),
          ),
      ],
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.persimmon.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.persimmon),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB25B2E),
            ),
          ),
        ],
      ),
    );
  }
}

/// 白底圆角信息面板。
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient});

  final RecipeIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFFF1E2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              ingredient.name,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.ink,
                height: 1.5,
              ),
            ),
          ),
          if (ingredient.amount.isNotEmpty) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Text(
                ingredient.amount,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.black45,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTheme.persimmon,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${step.order}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  step.text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.ink,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          if (step.children.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 27, top: 4),
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFFFE0C2), width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final child in step.children) _ChildStepRow(step: child),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChildStepRow extends StatelessWidget {
  const _ChildStepRow({required this.step});

  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.persimmon,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          if (step.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final child in step.children) _ChildStepRow(step: child),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
