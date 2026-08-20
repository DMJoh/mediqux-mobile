import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/widgets/mediqux_logo.dart';

class ServerSetupScreen extends ConsumerStatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _normaliseUrl(String raw) {
    var url = raw.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.endsWith('/api')) url = '$url/api';
    return url;
  }

  Future<bool> _testConnection(String url) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      // /health is a public endpoint — no auth needed
      final response = await dio.get<dynamic>('$url/health');
      return response.statusCode == 200;
    } on Object {
      return false;
    }
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = _normaliseUrl(_urlController.text);
    final reachable = await _testConnection(url);

    if (!mounted) return;

    if (!reachable) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not reach the server. '
            'Check the address and try again.';
      });
      return;
    }

    await ref.read(serverConfigProvider.notifier).setUrl(url);
    if (!mounted) return;
    final isLoggedIn = ref.read(authProvider).value != null;
    if (isLoggedIn) {
      context.go('/');
    }
    // If not logged in, router redirect navigates to /login.
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoggedIn = ref.watch(authProvider).value != null;

    // Pre-fill with the existing URL when opened from settings.
    if (!_initialized) {
      final existing = ref.read(serverConfigProvider).value;
      if (existing != null) {
        _urlController.text = existing.replaceFirst(RegExp(r'/api$'), '');
      }
      _initialized = true;
    }

    return Scaffold(
      body: Stack(
        children: [
          const FractionallySizedBox(
            alignment: Alignment.topCenter,
            heightFactor: 0.42,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.headerGradient),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (isLoggedIn)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(
                      color: Colors.white,
                      onPressed: () => context.pop(),
                    ),
                  ),
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
                        'Connect to your server',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
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
                              'Server Setup',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your Mediqux server address',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _urlController,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                labelText: 'Server Address',
                                hintText: 'http://192.168.1.5:3000',
                                prefixIcon: Icon(Icons.dns_rounded),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _connect(),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Server address is required';
                                }
                                final lower = v.trim().toLowerCase();
                                if (!lower.startsWith('http://') &&
                                    !lower.startsWith('https://')) {
                                  return 'Must start with '
                                      'http:// or https://';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(message: _errorMessage!),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _connect,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Connect'),
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
                                    'for the server address.',
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
