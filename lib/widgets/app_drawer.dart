import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/user.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/widgets/mediqux_logo.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(authProvider).valueOrNull;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(user: user),
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              route: '/',
              currentRoute: currentRoute,
            ),
            _NavItem(
              icon: Icons.people_rounded,
              label: 'Patients',
              route: '/patients',
              currentRoute: currentRoute,
            ),
            _NavItem(
              icon: Icons.business_rounded,
              label: 'Institutions',
              route: '/institutions',
              currentRoute: currentRoute,
            ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: cs.error,
              ),
              title: Text(
                'Sign Out',
                style: tt.bodyMedium?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                await ref
                    .read(authProvider.notifier)
                    .logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MediquxLogo(size: 40),
          const SizedBox(height: 12),
          Text(
            'Mediqux',
            style: tt.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (user case final u?) ...[
            const SizedBox(height: 4),
            Text(
              '${u.firstName} ${u.lastName}',
              style: tt.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              u.role,
              style: tt.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isActive = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: tt.bodyMedium?.copyWith(
          color: isActive ? cs.primary : cs.onSurface,
          fontWeight:
              isActive ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      tileColor: isActive
          ? cs.primaryContainer.withValues(alpha: 0.5)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }
}
