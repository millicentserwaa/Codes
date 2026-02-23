import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

// allow bypass navigation
import '../../main.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final err = await context.read<AuthService>().signUp(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kAuthDisabledForDebug) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Authentication disabled for debugging',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const MainShell())),
                  child: const Text('Continue to app'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: AppTheme.primary, size: 36),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                      child: Text('Create Account',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(fontSize: 24))),
                  Center(
                      child: Text('AF Screen · Cardiac Monitoring',
                          style: Theme.of(context).textTheme.bodyMedium)),
                  const SizedBox(height: 36),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppTheme.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.danger, fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: InputDecoration(
                      labelText: 'Password (min. 6 characters)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    obscureText: _obscure,
                    validator: (v) =>
                        v != _passCtrl.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!kAuthDisabledForDebug)
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen())),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14),
                            children: [
                              TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
