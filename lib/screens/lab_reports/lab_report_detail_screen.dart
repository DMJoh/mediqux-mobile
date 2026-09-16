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
import 'package:mediqux_mobile/widgets/glass_app_header.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/info_section.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';
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
      body: reportAsync.when(
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
        data: (report) {
          final dateFmt = DateFormat('MMM d, yyyy');
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GlassAppHeader(
                  title: report.testName,
                  onBack: () => context.pop(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () =>
                          context.push('/lab-reports/${report.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, ref, report),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Patient
                      InfoSection(
                        title: 'Patient',
                        rows: [
                          InfoRow(label: 'Name', value: report.patientName),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Test info
                      InfoSection(
                        title: 'Test Info',
                        rows: [
                          InfoRow(label: 'Test', value: report.testName),
                          InfoRow(
                            label: 'Date',
                            value: dateFmt.format(report.testDate),
                          ),
                          if (report.testType != null)
                            InfoRow(label: 'Type', value: report.testType!),
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
                        InfoSection(
                          title: 'Appointment',
                          rows: [
                            InfoRow(
                              label: 'Doctor',
                              value: report.doctorName.isEmpty
                                  ? '-'
                                  : report.doctorName,
                            ),
                            InfoRow(
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
                          icon: const Icon(Icons.open_in_new_outlined),
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
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAB VALUES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: glass.gradientStart,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < labValues.length; i++) ...[
            _LabValueRow(labValue: labValues[i]),
            if (i < labValues.length - 1)
              Divider(height: 1, thickness: 0.5, color: glass.glassBorder),
          ],
        ],
      ),
    );
  }
}

class _LabValueRow extends StatelessWidget {
  const _LabValueRow({required this.labValue});

  final LabValue labValue;

  StatusTone _statusTone(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'critical':
        return StatusTone.critical;
      case 'low':
        return StatusTone.warning;
      default:
        return StatusTone.positive;
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
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final tt = theme.textTheme;
    final tone = _statusTone(labValue.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labValue.parameterName,
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              StatusBadge.tone(
                context,
                label: labValue.status.toUpperCase(),
                tone: tone,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _displayValue(),
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (labValue.referenceRange != null)
                Text(
                  '  ·  Ref: ${labValue.referenceRange}',
                  style: tt.bodySmall?.copyWith(color: glass.muted),
                ),
            ],
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
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: glass.gradientStart,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
