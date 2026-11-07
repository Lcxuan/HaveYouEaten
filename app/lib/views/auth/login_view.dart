import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/config/api_config.dart';
import 'package:have_you_eaten/store/auth_store.dart';
import 'package:have_you_eaten/styles/app_theme.dart';
import 'package:have_you_eaten/utils/error_util.dart';

/// 登录页：手机号 + 密码登录，成功后进入首页。
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // 启动恢复出已登录状态时，直接进入首页。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authProvider).loggedIn) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 启动恢复较慢时，等登录态就绪后再跳转首页。
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.loggedIn) context.go('/home');
    });

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            children: [
              const Center(child: Text('🍚', style: TextStyle(fontSize: 46))),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  ApiConfig.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '手机号登录，家人朋友各记各的',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                  counterText: '',
                ),
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
                    return '请输入正确的手机号';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (password.length < 6 || password.length > 32) {
                    return '密码长度 6-32 位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('登录'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有账号？', style: TextStyle(color: Colors.black54)),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('手机号注册'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
