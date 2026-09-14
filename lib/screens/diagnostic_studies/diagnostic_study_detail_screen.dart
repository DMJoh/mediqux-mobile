import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study.dart';
import 'package:mediqux_mobile/providers/diagnostic_study_provider.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/glass_app_header.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/info_section.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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
                child: GlassAppHeader(
                  title: study.studyType,
                  onBack: () => context.pop(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
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
                      // Patient
                      InfoSection(
                        title: 'Patient',
                        rows: [
                          InfoRow(label: 'Name', value: study.patientName),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Study details
                      InfoSection(
                        title: 'Study Info',
                        rows: [
                          InfoRow(label: 'Type', value: study.studyType),
                          if (study.bodyRegion != null)
                            InfoRow(label: 'Region', value: study.bodyRegion!),
                          InfoRow(
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
                        InfoSection(
                          title: 'Physicians',
                          rows: [
                            if (study.orderingPhysician != null)
                              InfoRow(
                                label: 'Ordering',
                                value: study.orderingPhysician!.fullName,
                              ),
                            if (study.performingPhysician != null)
                              InfoRow(
                                label: 'Performing',
                                value: study.performingPhysician!.fullName,
                              ),
                          ],
                        ),
                      ],
                      // Institution
                      if (study.institution != null) ...[
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Institution',
                          rows: [
                            InfoRow(
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
                          icon: const Icon(Icons.open_in_new_outlined),
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
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final tt = theme.textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLINICAL INFO',
            style: tt.labelSmall?.copyWith(
              color: glass.gradientStart,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          if (study.clinicalIndication != null) ...[
            Text(
              'Indication',
              style: tt.bodySmall?.copyWith(
                color: glass.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(study.clinicalIndication!, style: tt.bodySmall),
            const SizedBox(height: 10),
          ],
          if (study.findings != null) ...[
            Text(
              'Findings',
              style: tt.bodySmall?.copyWith(
                color: glass.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(study.findings!, style: tt.bodySmall),
            const SizedBox(height: 10),
          ],
          if (study.conclusion != null) ...[
            Text(
              'Conclusion',
              style: tt.bodySmall?.copyWith(
                color: glass.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(study.conclusion!, style: tt.bodySmall),
          ],
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
