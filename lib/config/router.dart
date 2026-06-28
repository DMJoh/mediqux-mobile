import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/user.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/screens/auth/login_screen.dart';
import 'package:mediqux_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:mediqux_mobile/screens/institutions/institution_detail_screen.dart';
import 'package:mediqux_mobile/screens/institutions/institution_form_screen.dart';
import 'package:mediqux_mobile/screens/institutions/institutions_list_screen.dart';
import 'package:mediqux_mobile/screens/patients/patient_detail_screen.dart';
import 'package:mediqux_mobile/screens/patients/patient_form_screen.dart';
import 'package:mediqux_mobile/screens/patients/patients_list_screen.dart';
import 'package:mediqux_mobile/screens/setup/server_setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/setup', builder: (_, __) => const ServerSetupScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/institutions',
        builder: (_, __) => const InstitutionsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const InstitutionFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) {
              final id = state.pathParameters['id'] ?? '';
              return InstitutionDetailScreen(institutionId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return InstitutionFormScreen(institutionId: id);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/patients',
        builder: (_, __) => const PatientsListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, __) => const PatientFormScreen()),
          GoRoute(
            path: ':id',
            builder: (_, state) {
              final id = state.pathParameters['id'] ?? '';
              return PatientDetailScreen(patientId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return PatientFormScreen(patientId: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    _serverState = ref.read(serverConfigProvider);
    _authState = ref.read(authProvider);

    ref
      ..listen<AsyncValue<String?>>(serverConfigProvider, (_, next) {
        _serverState = next;
        notifyListeners();
      })
      ..listen<AsyncValue<User?>>(authProvider, (_, next) {
        _authState = next;
        notifyListeners();
      });
  }

  late AsyncValue<String?> _serverState;
  late AsyncValue<User?> _authState;

  String? redirect(BuildContext context, GoRouterState state) {
    if (_serverState.isLoading || _authState.isLoading) {
      return null;
    }

    final loc = state.matchedLocation;
    final hasServer = _serverState.valueOrNull != null;
    final isLoggedIn = _authState.valueOrNull != null;

    if (!hasServer && loc != '/setup') return '/setup';
    if (hasServer && !isLoggedIn && loc != '/login') {
      return '/login';
    }
    if (hasServer && isLoggedIn && (loc == '/login' || loc == '/setup')) {
      return '/';
    }
    return null;
  }
}
