import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInput;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/widgets/mediqux_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _serverError;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    if (!_passwordFocus.hasFocus || _isLoading) return;
    final bottom =
        WidgetsBinding
            .instance
            .platformDispatcher
            .implicitView
            ?.viewInsets
            .bottom ??
        0.0;
    if (bottom == 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _passwordFocus.hasFocus && !_isLoading) {
          _passwordFocus.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordFocus.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normaliseUrl(String raw) {
    var url = raw.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.endsWith('/api')) url = '$url/api';
    return url;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _serverError = null;
    });

    final url = _normaliseUrl(_serverController.text);
    await ref.read(serverConfigProvider.notifier).setUrl(url);
    if (!mounted) return;

    await ref
        .read(authProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (ref.read(authProvider).value != null) {
      TextInput.finishAutofillContext();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final existing = ref.read(serverConfigProvider).value;
      if (existing != null) {
        _serverController.text = existing.replaceFirst(RegExp(r'/api$'), '');
      }
      _initialized = true;
    }

    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoading = _isLoading || authState.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          const FractionallySizedBox(
            alignment: Alignment.topCenter,
            heightFactor: 0.38,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.headerGradient),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MediquxLogo(),
                      const SizedBox(height: 12),
                      Text(
                        'Mediqux',
                        style: tt.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
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

                Expanded(
                  flex: 7,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign In',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your server and credentials',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _serverController,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Server Address',
                                hintText: 'http://192.168.1.5:3000',
                                prefixIcon: Icon(Icons.dns_rounded),
                              ),
                              onChanged: (_) {
                                if (_serverError != null) {
                                  setState(() => _serverError = null);
                                }
                              },
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Server address is required';
                                }
                                final lower = v.trim().toLowerCase();
                                if (!lower.startsWith('http://') &&
                                    !lower.startsWith('https://')) {
                                  return 'Must start with http:// or https://';
                                }
                                return null;
                              },
                            ),

                            if (_serverError != null) ...[
                              const SizedBox(height: 10),
                              _ErrorBanner(message: _serverError!),
                            ],

                            const SizedBox(height: 14),

                            AutofillGroup(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Username or Email',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Username is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _submit(),
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
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Password is required'
                                        : null,
                                  ),
                                ],
                              ),
                            ),

                            if (authState.hasError) ...[
                              const SizedBox(height: 14),
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

                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Contact your Mediqux administrator '
                                    'for the server address and credentials.',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
