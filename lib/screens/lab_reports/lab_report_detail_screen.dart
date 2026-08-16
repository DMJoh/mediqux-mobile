import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/lab_report_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class LabReportDetailScreen extends ConsumerWidget {
  const LabReportDetailScreen({required this.reportId, super.key});

  final String reportId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LabReport report,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete lab report?'),
        content: Text('Delete "${report.testName}"? This cannot be undone.'),
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
    await ref.read(labReportsProvider.notifier).delete(report.id);
    if (context.mounted) context.pop();
  }

  Future<void> _openFile(
    BuildContext context,
    WidgetRef ref,
    String reportId,
  ) async {
    try {
      final dio = ref.read(dioProvider);
      final serverUrl = ref.read(serverConfigProvider).value ?? '';
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = '${tmpDir.path}/mediqux_report_$reportId.pdf';
      await dio.download('$serverUrl/test-results/$reportId/view', tmpPath);
      final result = await OpenFile.open(tmpPath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open PDF: ${result.message}')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final reportAsync = ref.watch(labReportDetailProvider(reportId));

    return Scaffold(
      backgroundColor: cs.surface,
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
        data: (report) {
          final dateFmt = DateFormat('MMM d, yyyy');
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
                    onPressed: () =>
                        context.push('/lab-reports/${report.id}/edit'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.white),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, ref, report),
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
                    report.testName,
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
                          Icons.science_rounded,
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
                      // Patient
                      _InfoSection(
                        title: 'Patient',
                        rows: [
                          _InfoRow(
                            icon: Icons.person_rounded,
                            label: 'Name',
                            value: report.patientName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Test info
                      _InfoSection(
                        title: 'Test Info',
                        rows: [
                          _InfoRow(
                            icon: Icons.science_rounded,
                            label: 'Test',
                            value: report.testName,
                          ),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: dateFmt.format(report.testDate),
                          ),
                          if (report.testType != null)
                            _InfoRow(
                              icon: Icons.category_rounded,
                              label: 'Type',
                              value: report.testType!,
                            ),
                        ],
                      ),
                      if (report.labValues != null &&
                          report.labValues!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _LabValuesSection(labValues: report.labValues!),
                      ],
                      if (report.doctorName.isNotEmpty ||
                          report.institutionName != null) ...[
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: 'Appointment',
                          rows: [
                            _InfoRow(
                              icon: Icons.medical_services_rounded,
                              label: 'Doctor',
                              value: report.doctorName.isEmpty
                                  ? '-'
                                  : report.doctorName,
                            ),
                            _InfoRow(
                              icon: Icons.business_rounded,
                              label: 'Institution',
                              value: report.institutionName ?? '-',
                            ),
                          ],
                        ),
                      ],
                      if (report.notes != null) ...[
                        const SizedBox(height: 12),
                        _NotesSection(content: report.notes!),
                      ],
                      if (report.hasFile) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _openFile(context, ref, report.id),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('View Report'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
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

class _LabValuesSection extends StatelessWidget {
  const _LabValuesSection({required this.labValues});

  final List<LabValue> labValues;

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
            'Lab Values',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...labValues.map((lv) => _LabValueRow(labValue: lv)),
        ],
      ),
    );
  }
}

class _LabValueRow extends StatelessWidget {
  const _LabValueRow({required this.labValue});

  final LabValue labValue;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'low':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _displayValue() {
    final v = labValue.value;
    final str = v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(2);
    return labValue.unit != null ? '$str ${labValue.unit}' : str;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = _statusColor(labValue.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        labValue.parameterName,
                        style: tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        labValue.status.toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _displayValue(),
                      style: tt.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (labValue.referenceRange != null)
                      Text(
                        '  ·  Ref: ${labValue.referenceRange}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
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

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.content});

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
            'Notes',
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
