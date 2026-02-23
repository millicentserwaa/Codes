import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'signup_screen.dart';

// for navigation to main shell when auth is disabled
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final err = await context.read<AuthService>().signIn(
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
    // if authentication is turned off, show simple continue screen
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
                  // Logo / header
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
                    child: Text('AF Screen',
                        style: Theme.of(context).textTheme.displayMedium),
                  ),
                  Center(
                    child: Text('Cardiac Monitoring',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 40),

                  Text('Sign In',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),

                  // Error banner
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
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password is required' : null,
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
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!kAuthDisabledForDebug)
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen())),
                        child: RichText(
                          text: const TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14),
                            children: [
                              TextSpan(
                                  text: 'Sign Up',
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
