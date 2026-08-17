import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/prescription/prescription.dart';
import 'package:mediqux_mobile/providers/prescription_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/detail_hero.dart';

class PrescriptionDetailScreen extends ConsumerWidget {
  const PrescriptionDetailScreen({required this.prescriptionId, super.key});

  final String prescriptionId;

  Color _statusColor(BuildContext context, String? status) {
    final cs = Theme.of(context).colorScheme;
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'discontinued':
        return cs.onSurfaceVariant;
      case 'completed':
        return cs.primary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Prescription rx,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete prescription?'),
        content: Text(
          'Delete prescription for "${rx.medicationDisplay}"? '
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
    await ref.read(prescriptionsProvider.notifier).delete(rx.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final rxAsync = ref.watch(prescriptionDetailProvider(prescriptionId));

    return Scaffold(
      backgroundColor: cs.surface,
      body: rxAsync.when(
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
        data: (rx) {
          final statusColor = _statusColor(context, rx.status);
          final dateFmt = DateFormat('MMM d, yyyy');
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DetailHero(
                  title: rx.medicationDisplay,
                  onBack: () => context.pop(),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (v) {
                        if (v == 'edit') {
                          context.push('/prescriptions/${rx.id}/edit');
                        } else if (v == 'delete') {
                          _confirmDelete(context, ref, rx);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
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
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Status chip
                      if (rx.status != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              rx.status!,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      // Patient info
                      _InfoSection(
                        title: 'Patient',
                        rows: [
                          _InfoRow(
                            icon: Icons.person_rounded,
                            label: 'Name',
                            value: rx.patientName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Medication details
                      _InfoSection(
                        title: 'Medication',
                        rows: [
                          _InfoRow(
                            icon: Icons.medication_rounded,
                            label: 'Name',
                            value: rx.medicationDisplay,
                          ),
                          _InfoRow(
                            icon: Icons.scale_rounded,
                            label: 'Dosage',
                            value: rx.dosage,
                          ),
                          _InfoRow(
                            icon: Icons.repeat_rounded,
                            label: 'Frequency',
                            value: rx.frequency,
                          ),
                          _InfoRow(
                            icon: Icons.timer_rounded,
                            label: 'Duration',
                            value: rx.duration,
                          ),
                          if (rx.instructions != null)
                            _InfoRow(
                              icon: Icons.info_outline_rounded,
                              label: 'Instructions',
                              value: rx.instructions!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Appointment info
                      _InfoSection(
                        title: 'Appointment',
                        rows: [
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: rx.appointmentDate != null
                                ? dateFmt.format(rx.appointmentDate!)
                                : '-',
                          ),
                          _InfoRow(
                            icon: Icons.medical_services_rounded,
                            label: 'Doctor',
                            value: rx.doctorName.isEmpty ? '-' : rx.doctorName,
                          ),
                          _InfoRow(
                            icon: Icons.business_rounded,
                            label: 'Institution',
                            value: rx.institutionName ?? '-',
                          ),
                        ],
                      ),
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
            width: 80,
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
