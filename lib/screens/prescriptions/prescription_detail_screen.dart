import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/prescription/prescription.dart';
import 'package:mediqux_mobile/providers/prescription_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/glass_app_header.dart';
import 'package:mediqux_mobile/widgets/info_section.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

class PrescriptionDetailScreen extends ConsumerWidget {
  const PrescriptionDetailScreen({required this.prescriptionId, super.key});

  final String prescriptionId;

  StatusTone _statusTone(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return StatusTone.positive;
      case 'discontinued':
        return StatusTone.critical;
      case 'completed':
        return StatusTone.neutral;
      default:
        return StatusTone.neutral;
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
          final dateFmt = DateFormat('MMM d, yyyy');
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GlassAppHeader(
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
                              Icon(Icons.edit_outlined, size: 20),
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
                      // Status chip
                      if (rx.status != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StatusBadge.tone(
                              context,
                              label: rx.status!,
                              tone: _statusTone(rx.status),
                            ),
                          ),
                        ),
                      // Patient info
                      InfoSection(
                        title: 'Patient',
                        rows: [InfoRow(label: 'Name', value: rx.patientName)],
                      ),
                      const SizedBox(height: 12),
                      // Medication details
                      InfoSection(
                        title: 'Medication',
                        rows: [
                          InfoRow(label: 'Name', value: rx.medicationDisplay),
                          InfoRow(label: 'Dosage', value: rx.dosage),
                          InfoRow(label: 'Frequency', value: rx.frequency),
                          InfoRow(label: 'Duration', value: rx.duration),
                          if (rx.instructions != null)
                            InfoRow(
                              label: 'Instructions',
                              value: rx.instructions!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Appointment info
                      InfoSection(
                        title: 'Appointment',
                        rows: [
                          InfoRow(
                            label: 'Date',
                            value: rx.appointmentDate != null
                                ? dateFmt.format(rx.appointmentDate!)
                                : '-',
                          ),
                          InfoRow(
                            label: 'Doctor',
                            value: rx.doctorName.isEmpty ? '-' : rx.doctorName,
                          ),
                          InfoRow(
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
