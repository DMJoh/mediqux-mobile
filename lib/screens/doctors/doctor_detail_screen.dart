import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';
import 'package:mediqux_mobile/providers/doctor_provider.dart';

class DoctorDetailScreen extends ConsumerWidget {
  const DoctorDetailScreen({required this.doctorId, super.key});

  final String doctorId;

  static const _palette = [
    Color(0xFF2196F3),
    Color(0xFF43A047),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFF00ACC1),
    Color(0xFFFFB300),
  ];

  Color _avatarColor(String name) {
    final sum = name.codeUnits.fold(0, (a, b) => a + b);
    return _palette[sum % _palette.length];
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Doctor doctor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete doctor?'),
        content: Text(
          'Delete "${doctor.fullName}"? '
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
    await ref.read(doctorsProvider.notifier).delete(doctor.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));

    return Scaffold(
      backgroundColor: cs.surface,
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(e.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
        data: (doctor) {
          final avatarColor = _avatarColor(doctor.fullName);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                leading: BackButton(
                  color: Colors.white,
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    tooltip: 'Edit',
                    onPressed: () => context.push('/doctors/${doctor.id}/edit'),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                    onSelected: (v) {
                      if (v == 'delete') {
                        _confirmDelete(context, ref, doctor);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
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
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(
                    left: 56,
                    right: 56,
                    bottom: 16,
                  ),
                  title: Text(
                    doctor.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.headerGradient,
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          doctor.initials,
                          style: TextStyle(
                            color: avatarColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoSection(
                        title: 'Personal Info',
                        rows: [
                          _InfoRow(
                            icon: Icons.medical_services_rounded,
                            label: 'Specialty',
                            value: doctor.specialty ?? '-',
                          ),
                          _InfoRow(
                            icon: Icons.badge_rounded,
                            label: 'License',
                            value: doctor.licenseNumber ?? '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoSection(
                        title: 'Contact',
                        rows: [
                          _InfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone',
                            value: doctor.phone ?? '-',
                          ),
                          _InfoRow(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            value: doctor.email ?? '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InstitutionsSection(doctor: doctor),
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

class _InstitutionsSection extends StatelessWidget {
  const _InstitutionsSection({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final institutions = doctor.institutions ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Institutions',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: Text(
                  '${institutions.length}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (institutions.isEmpty)
            Text(
              'No institutions assigned.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            ...institutions.map(
              (inst) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        size: 18,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inst.name,
                            style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          if (inst.type != null)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: cs.tertiaryContainer,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                inst.type!,
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
