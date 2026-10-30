import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:have_you_eaten/app/app_router.dart';
import 'package:have_you_eaten/theme/app_theme.dart';
import 'package:have_you_eaten/providers/auth_provider.dart';

/// 注册页：手机号 + 密码 + 可选昵称，成功后自动登录并返回。
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).register(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
      );
      if (mounted) context.pop();
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
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            children: [
              Center(
                child: Text(
                  '手机号注册',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '只需手机号 + 密码，昵称可不填',
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
              const SizedBox(height: 13),
              TextFormField(
                controller: _nicknameController,
                maxLength: 32,
                decoration: const InputDecoration(
                  labelText: '昵称（选填，默认「用户 + 尾号」）',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  counterText: '',
                ),
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
                    : const Text('注册'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('已有账号？', style: TextStyle(color: Colors.black54)),
                  TextButton(
                    onPressed: () => context.goNamed(AppRouteNames.login),
                    child: const Text('去登录'),
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
