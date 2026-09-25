import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';
import 'package:mediqux_mobile/screens/institutions/institutions_list_screen.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/glass_app_header.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_avatar.dart';
import 'package:mediqux_mobile/widgets/info_section.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

class InstitutionDetailScreen extends ConsumerWidget {
  const InstitutionDetailScreen({required this.institutionId, super.key});

  final String institutionId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Institution institution,
  ) async {
    if (institution.doctorCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot delete'),
          content: Text(
            '"${institution.name}" has '
            '${institution.doctorCount} associated '
            'doctor${institution.doctorCount != 1 ? 's' : ''}. '
            'Remove doctor associations first.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete institution?'),
        content: Text(
          'Delete "${institution.name}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(institutionsProvider.notifier).delete(institution.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final institutionAsync = ref.watch(
      institutionDetailProvider(institutionId),
    );

    return Scaffold(
      body: institutionAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            strokeWidth: 3,
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(friendlyError(e)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
        data: (institution) {
          final color = institutionColor(institution.type);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GlassAppHeader(
                  title: institution.name,
                  onBack: () => context.pop(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () =>
                          context.push('/institutions/${institution.id}/edit'),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (v) {
                        if (v == 'delete') {
                          _confirmDelete(context, ref, institution);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: cs.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: cs.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (institution.type != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              StatusBadge(
                                label: institution.type!,
                                color: color,
                              ),
                            ],
                          ),
                        ),
                      InfoSection(
                        title: 'Contact',
                        rows: [
                          InfoRow(
                            label: 'Phone',
                            value: institution.phone ?? '-',
                          ),
                          InfoRow(
                            label: 'Email',
                            value: institution.email ?? '-',
                          ),
                          if (institution.website != null)
                            InfoRow(
                              label: 'Website',
                              value: institution.website!,
                            ),
                        ],
                      ),
                      if (institution.address != null) ...[
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Address',
                          rows: [
                            InfoRow(
                              label: 'Address',
                              value: institution.address!,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      _DoctorsSection(institution: institution),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DoctorsSection extends StatelessWidget {
  const _DoctorsSection({required this.institution});

  final Institution institution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final doctors = institution.doctors ?? [];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ASSOCIATED DOCTORS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: glass.gradientStart,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: glass.glass2,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  border: Border.all(color: glass.glassBorder),
                ),
                child: Text(
                  '${doctors.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (doctors.isEmpty)
            Text(
              'No doctors assigned to this institution.',
              style: theme.textTheme.bodySmall?.copyWith(color: glass.muted),
            )
          else
            ...doctors.map((d) {
              final firstInitial = d.firstName.isNotEmpty ? d.firstName[0] : '';
              final lastInitial = d.lastName.isNotEmpty ? d.lastName[0] : '';
              final initials = '$firstInitial$lastInitial'.toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    GradientAvatar(initials: initials, size: 36, glow: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.fullName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (d.specialty != null)
                            Text(
                              d.specialty!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: glass.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
