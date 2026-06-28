import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/widgets/mediqux_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          const FractionallySizedBox(
            alignment: Alignment.topCenter,
            heightFactor: 0.45,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.headerGradient),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Brand area ──────────────────────────
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MediquxLogo(size: 72),
                      const SizedBox(height: 16),
                      Text(
                        'Mediqux',
                        style: tt.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient Management System',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form card ───────────────────────────
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome back',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username or Email',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              enableSuggestions: false,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Username is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            if (authState.hasError) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(
                                message: authState.error is String
                                    ? authState.error! as String
                                    : 'An unexpected error occurred',
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: isLoading ? null : _submit,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
