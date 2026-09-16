import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/glass_app_header.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/info_section.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

StatusTone _statusTone(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return StatusTone.positive;
    case 'cancelled':
      return StatusTone.critical;
    case 'scheduled':
    default:
      return StatusTone.neutral;
  }
}

class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({required this.appointmentId, super.key});

  final String appointmentId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Appointment apt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete appointment?'),
        content: Text(
          'Delete appointment for "${apt.patientName}"? '
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
    try {
      await ref.read(appointmentsProvider.notifier).delete(apt.id);
      if (context.mounted) context.pop();
    } on Object catch (e) {
      final msg = friendlyError(e);
      final isConflict = msg.contains('409') || msg.contains('test result');
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cannot delete'),
            content: Text(
              isConflict
                  ? 'This appointment has linked test results '
                        'and cannot be deleted.'
                  : msg,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final aptAsync = ref.watch(appointmentDetailProvider(appointmentId));

    return Scaffold(
      body: aptAsync.when(
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
        data: (apt) {
          final dateFmt = DateFormat('EEEE, MMMM d, yyyy');
          final timeFmt = DateFormat('h:mm a');
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(appointmentDetailProvider(appointmentId).future),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GlassAppHeader(
                    title: apt.type ?? 'Appointment',
                    onBack: () => context.pop(),
                    actions: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (v) {
                          if (v == 'edit') {
                            context.push('/appointments/${apt.id}/edit');
                          } else if (v == 'delete') {
                            _confirmDelete(context, ref, apt);
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
                                Text(
                                  'Delete',
                                  style: TextStyle(color: cs.error),
                                ),
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
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(
                            children: [
                              Text(
                                'Status',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              StatusBadge.tone(
                                context,
                                label: apt.status,
                                tone: _statusTone(apt.status),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Appointment',
                          rows: [
                            InfoRow(
                              label: 'Date',
                              value: dateFmt.format(apt.appointmentDate),
                            ),
                            InfoRow(
                              label: 'Time',
                              value: timeFmt.format(apt.appointmentDate),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Patient',
                          rows: [
                            InfoRow(label: 'Name', value: apt.patientName),
                            InfoRow(
                              label: 'Phone',
                              value: apt.patientPhone ?? '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Doctor',
                          rows: [
                            InfoRow(
                              label: 'Name',
                              value: apt.doctorName.isEmpty
                                  ? '-'
                                  : apt.doctorName,
                            ),
                            InfoRow(
                              label: 'Specialty',
                              value: apt.doctorSpecialty ?? '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Institution',
                          rows: [
                            InfoRow(
                              label: 'Name',
                              value: apt.institutionName ?? '-',
                            ),
                            InfoRow(
                              label: 'Type',
                              value: apt.institutionType ?? '-',
                            ),
                          ],
                        ),
                        if (apt.notes != null) ...[
                          const SizedBox(height: 12),
                          InfoSection(
                            title: 'Notes',
                            rows: [InfoRow(label: 'Notes', value: apt.notes!)],
                          ),
                        ],
                        if (apt.diagnosis != null) ...[
                          const SizedBox(height: 12),
                          InfoSection(
                            title: 'Diagnosis',
                            rows: [
                              InfoRow(
                                label: 'Diagnosis',
                                value: apt.diagnosis!,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
