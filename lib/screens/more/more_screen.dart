import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/user.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_avatar.dart';
import 'package:mediqux_mobile/widgets/nav_list_tile.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'More',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              _ProfileCard(user: user),
              const SizedBox(height: 20),
            ],
            const _SectionLabel('Clinical'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  NavListTile(
                    icon: Icons.calendar_month_outlined,
                    label: 'Appointments',
                    onTap: () => context.push('/appointments'),
                  ),
                  const Divider(height: 1),
                  NavListTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Doctors',
                    onTap: () => context.push('/doctors'),
                  ),
                  const Divider(height: 1),
                  NavListTile(
                    icon: Icons.business_outlined,
                    label: 'Institutions',
                    onTap: () => context.push('/institutions'),
                  ),
                  const Divider(height: 1),
                  NavListTile(
                    icon: Icons.health_and_safety_outlined,
                    label: 'Conditions',
                    onTap: () => context.push('/conditions'),
                  ),
                  const Divider(height: 1),
                  NavListTile(
                    icon: Icons.medication_outlined,
                    label: 'Medications',
                    onTap: () => context.push('/medications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Account'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  NavListTile(
                    icon: Icons.dns_outlined,
                    label: 'Change Server',
                    subtitle: 'Sign out and update server address',
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                    },
                  ),
                  const Divider(height: 1),
                  NavListTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    labelColor: theme.colorScheme.error,
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: glass.muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;

    return GlassCard(
      child: Row(
        children: [
          GradientAvatar(initials: '${user.firstName[0]}${user.lastName[0]}'),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: glass.muted,
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
