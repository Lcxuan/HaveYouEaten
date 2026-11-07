import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/config/api_config.dart';
import 'package:have_you_eaten/layout/main_layout.dart';
import 'package:have_you_eaten/store/auth_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';

/// 设置页签：账号卡、偏好/黑名单入口、版本信息与退出登录，对应原型第 ⑩ 屏。
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).session;
    final nickname = session?.nickname ?? '';
    final loggedIn = session != null;

    return MainLayout(
      title: '设置',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UserCard(nickname: nickname, loggedIn: loggedIn),
          const SizedBox(height: 14),
          if (!loggedIn) ...[
            FilledButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('登录 / 注册'),
            ),
            const SizedBox(height: 14),
          ],
          _SettingsGroup(
            children: [
              _SettingRow(
                icon: Icons.tune_rounded,
                label: '抽签偏好',
                value: '未设置',
                onTap: () => _comingSoon(context),
              ),
              _SettingRow(
                icon: Icons.block_rounded,
                label: '黑名单管理',
                value: '0 项',
                onTap: () => _comingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            children: [
              _SettingRow(
                icon: Icons.info_outline_rounded,
                label: '版本',
                value: 'v${ApiConfig.appVersion}',
              ),
            ],
          ),
          if (loggedIn) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.chili,
                side: const BorderSide(color: Color(0xFFF3C6C6), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('退出登录'),
            ),
          ],
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('功能待实现')));
  }

  /// 退出登录二次确认，防止误触。
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
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
              const SizedBox(height: 16),
              const Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '确定要退出当前账号吗？\n记录 / 收藏 / 黑名单仍保留在云端',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppTheme.ink,
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.chili,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go('/home');
  }
}

/// 账号卡：登录态、昵称与同步说明。
class _UserCard extends StatelessWidget {
  const _UserCard({required this.nickname, required this.loggedIn});

  final String nickname;
  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.persimmon, Color(0xFFE8503A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8503A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        loggedIn ? nickname : '未登录',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        loggedIn ? '已登录' : '游客',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  loggedIn ? '记录 / 收藏 / 黑名单云端同步' : '登录后记录 / 收藏云端同步',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 设置分组卡片。
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.ink.withValues(alpha: 0.08),
              ),
          ],
        ],
      ),
    );
  }
}

/// 单行设置项：图标 + 标题 + 右侧值/箭头。
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.ink),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFD8C6AE),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
