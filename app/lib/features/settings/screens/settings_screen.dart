import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/app/app_router.dart';
import 'package:have_you_eaten/config/api_config.dart';
import 'package:have_you_eaten/providers/auth_provider.dart';

/// 原型「餐桌暖色系」取色：柿橙主行动色 / 辣红警示色 / 米线分隔色。
const _persimmon = Color(0xFFFF6B35);
const _persimmonDeep = Color(0xFFE8503A);
const _chili = Color(0xFFD7263D);
const _line = Color(0xFFF0E4D3);
const _muted = Color(0xFF8A7A6D);
const _soft = Color(0xFFFFF1E2);

/// 设置页：账号卡、偏好入口与退出登录，对应原型图 ⑩。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: auth.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _AccountCard(
                  loggedIn: auth.loggedIn,
                  nickname: auth.nickname,
                  onTap: auth.loggedIn
                      ? null
                      : () => context.pushNamed(AppRouteNames.login),
                ),
                const SizedBox(height: 14),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.tune_rounded,
                      title: '抽签偏好',
                      onTap: () => _comingSoon(context),
                    ),
                    _SettingsRow(
                      icon: Icons.block_rounded,
                      title: '黑名单管理',
                      onTap: () => _comingSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: '版本',
                      value: ApiConfig.appVersion,
                    ),
                  ],
                ),
                if (auth.loggedIn) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _confirmLogout(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _chili,
                      side: const BorderSide(color: Color(0xFFF3C6C6), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      '退出登录',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('功能开发中，敬请期待')));
  }

  /// 退出登录：底部弹层二次确认，与原型 ⑩ 一致。
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2D4C0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '退出登录',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '确定要退出当前账号吗？\n记录 / 收藏 / 黑名单仍保留在云端',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _muted, height: 1.7),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: _line, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _chili,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('退出'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

/// 账号卡：已登录为柿橙渐变卡（昵称 + 已登录角标），未登录为米色引导卡。
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.loggedIn, this.nickname, this.onTap});

  final bool loggedIn;
  final String? nickname;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: loggedIn
            ? const LinearGradient(colors: [_persimmon, _persimmonDeep])
            : null,
        color: loggedIn ? null : _soft,
        borderRadius: BorderRadius.circular(18),
        boxShadow: loggedIn
            ? const [
                BoxShadow(
                  color: Color(0x40E8503A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: loggedIn
                      ? Colors.white24
                      : Colors.white,
                  child: Icon(
                    Icons.rice_bowl_rounded,
                    size: 24,
                    color: loggedIn ? Colors.white : _persimmon,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            loggedIn
                                ? (nickname?.isNotEmpty == true
                                      ? nickname!
                                      : '已登录')
                                : '未登录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: loggedIn ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (loggedIn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '已登录',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!loggedIn) ...[
                        const SizedBox(height: 3),
                        const Text(
                          '点击使用手机号登录',
                          style: TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!loggedIn)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 分组卡片：白色圆角容器，行间细分隔线。
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: _line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 设置行：图标 + 标题 + 可选右侧取值 + 可选箭头。
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _persimmon),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFD8C6AE),
              ),
          ],
        ),
      ),
    );
  }
}
