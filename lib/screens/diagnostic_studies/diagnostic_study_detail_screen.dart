import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study.dart';
import 'package:mediqux_mobile/providers/diagnostic_study_provider.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mediqux_mobile/widgets/detail_hero.dart';

class DiagnosticStudyDetailScreen extends ConsumerWidget {
  const DiagnosticStudyDetailScreen({required this.studyId, super.key});

  final String studyId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DiagnosticStudy study,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete study?'),
        content: Text('Delete "${study.studyType}"? This cannot be undone.'),
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
    await ref.read(diagnosticStudiesProvider.notifier).delete(study.id);
    if (context.mounted) context.pop();
  }

  Future<void> _openAttachment(
    BuildContext context,
    WidgetRef ref,
    String studyId,
  ) async {
    try {
      final dio = ref.read(dioProvider);
      final serverUrl = ref.read(serverConfigProvider).value ?? '';
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = '${tmpDir.path}/mediqux_study_$studyId.pdf';
      await dio.download(
        '$serverUrl/diagnostic-studies/$studyId/view',
        tmpPath,
      );
      final result = await OpenFile.open(tmpPath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: ${result.message}')),
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
    final studyAsync = ref.watch(diagnosticStudyDetailProvider(studyId));

    return Scaffold(
      backgroundColor: cs.surface,
      body: studyAsync.when(
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
        data: (study) {
          final dateFmt = DateFormat('MMM d, yyyy');
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DetailHero(
                  title: study.studyType,
                  onBack: () => context.pop(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: 'Edit',
                      onPressed: () =>
                          context.push('/diagnostic-studies/${study.id}/edit'),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (v) {
                        if (v == 'delete') {
                          _confirmDelete(context, ref, study);
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
                            value: study.patientName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Study details
                      _InfoSection(
                        title: 'Study Info',
                        rows: [
                          _InfoRow(
                            icon: Icons.document_scanner_rounded,
                            label: 'Type',
                            value: study.studyType,
                          ),
                          if (study.bodyRegion != null)
                            _InfoRow(
                              icon: Icons.accessibility_rounded,
                              label: 'Region',
                              value: study.bodyRegion!,
                            ),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: dateFmt.format(study.studyDate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Clinical info
                      if (study.clinicalIndication != null ||
                          study.findings != null ||
                          study.conclusion != null)
                        _ClinicalSection(study: study),
                      // Physicians
                      if (study.orderingPhysician != null ||
                          study.performingPhysician != null) ...[
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: 'Physicians',
                          rows: [
                            if (study.orderingPhysician != null)
                              _InfoRow(
                                icon: Icons.medical_services_rounded,
                                label: 'Ordering',
                                value: study.orderingPhysician!.fullName,
                              ),
                            if (study.performingPhysician != null)
                              _InfoRow(
                                icon: Icons.medical_services_outlined,
                                label: 'Performing',
                                value: study.performingPhysician!.fullName,
                              ),
                          ],
                        ),
                      ],
                      // Institution
                      if (study.institution != null) ...[
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: 'Institution',
                          rows: [
                            _InfoRow(
                              icon: Icons.business_rounded,
                              label: 'Name',
                              value: study.institution!.name,
                            ),
                          ],
                        ),
                      ],
                      // Notes
                      if (study.notes != null) ...[
                        const SizedBox(height: 12),
                        _NotesSection(content: study.notes!),
                      ],
                      // Attachment
                      if (study.hasAttachment) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              _openAttachment(context, ref, study.id),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('View Attachment'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                        if (study.attachmentOriginalName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            study.attachmentOriginalName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

class _ClinicalSection extends StatelessWidget {
  const _ClinicalSection({required this.study});

  final DiagnosticStudy study;

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
            'Clinical Info',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (study.clinicalIndication != null) ...[
            Text(
              'Indication',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              study.clinicalIndication!,
              style: tt.bodySmall?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 10),
          ],
          if (study.findings != null) ...[
            Text(
              'Findings',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              study.findings!,
              style: tt.bodySmall?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 10),
          ],
          if (study.conclusion != null) ...[
            Text(
              'Conclusion',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              study.conclusion!,
              style: tt.bodySmall?.copyWith(color: cs.onSurface),
            ),
          ],
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
