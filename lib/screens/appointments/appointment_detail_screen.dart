import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({required this.appointmentId, super.key});

  final String appointmentId;

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'scheduled':
        return cs.primary;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return cs.onSurfaceVariant;
      default:
        return cs.onSurfaceVariant;
    }
  }

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
      final msg = e.toString();
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
      backgroundColor: cs.surface,
      body: aptAsync.when(
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
        data: (apt) {
          final dateFmt = DateFormat('EEEE, MMMM d, yyyy');
          final timeFmt = DateFormat('h:mm a');
          final statusColor = _statusColor(context, apt.status);
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
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
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
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(
                    left: 56,
                    right: 56,
                    bottom: 16,
                  ),
                  title: Text(
                    apt.type ?? 'Appointment',
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
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 30,
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
                      // Status + Date
                      _InfoSection(
                        title: 'Appointment',
                        rows: [
                          _InfoRow(
                            icon: Icons.circle,
                            label: 'Status',
                            value: apt.status,
                            valueColor: statusColor,
                          ),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: dateFmt.format(apt.appointmentDate),
                          ),
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: 'Time',
                            value: timeFmt.format(apt.appointmentDate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Patient
                      _InfoSection(
                        title: 'Patient',
                        rows: [
                          _InfoRow(
                            icon: Icons.person_rounded,
                            label: 'Name',
                            value: apt.patientName,
                          ),
                          _InfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone',
                            value: apt.patientPhone ?? '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Doctor
                      _InfoSection(
                        title: 'Doctor',
                        rows: [
                          _InfoRow(
                            icon: Icons.medical_services_rounded,
                            label: 'Name',
                            value: apt.doctorName.isEmpty
                                ? '-'
                                : apt.doctorName,
                          ),
                          _InfoRow(
                            icon: Icons.star_rounded,
                            label: 'Specialty',
                            value: apt.doctorSpecialty ?? '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Institution
                      _InfoSection(
                        title: 'Institution',
                        rows: [
                          _InfoRow(
                            icon: Icons.business_rounded,
                            label: 'Name',
                            value: apt.institutionName ?? '-',
                          ),
                          _InfoRow(
                            icon: Icons.category_rounded,
                            label: 'Type',
                            value: apt.institutionType ?? '-',
                          ),
                        ],
                      ),
                      if (apt.notes != null) ...[
                        const SizedBox(height: 12),
                        _NotesSection(title: 'Notes', content: apt.notes!),
                      ],
                      if (apt.diagnosis != null) ...[
                        const SizedBox(height: 12),
                        _NotesSection(
                          title: 'Diagnosis',
                          content: apt.diagnosis!,
                        ),
                      ],
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
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

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
                color: valueColor ?? cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.title, required this.content});

  final String title;
  final String content;

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
          const SizedBox(height: 8),
          Text(content, style: tt.bodySmall?.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}
