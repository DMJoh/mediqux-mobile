import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mediqux_mobile/config/router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Pre-warm auth providers so the router never enters a loading state.
  // Providers resolve in <50 ms (secure storage reads); Android's native
  // launch theme covers this brief delay.
  final container = ProviderContainer();
  await container.read(serverConfigProvider.future);
  await container.read(authProvider.future);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MediquxApp(),
    ),
  );
}

class MediquxApp extends ConsumerWidget {
  const MediquxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Mediqux',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
