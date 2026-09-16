import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study.dart';
import 'package:mediqux_mobile/providers/diagnostic_study_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';

class DiagnosticStudiesListScreen extends ConsumerStatefulWidget {
  const DiagnosticStudiesListScreen({super.key});

  @override
  ConsumerState<DiagnosticStudiesListScreen> createState() =>
      _DiagnosticStudiesListScreenState();
}

class _DiagnosticStudiesListScreenState
    extends ConsumerState<DiagnosticStudiesListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DiagnosticStudy> _applySearch(List<DiagnosticStudy> items) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((s) {
      return s.studyType.toLowerCase().contains(q) ||
          s.patientName.toLowerCase().contains(q) ||
          (s.bodyRegion?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  IconData _studyIcon(String studyType) {
    switch (studyType) {
      case 'Echocardiogram':
        return Icons.favorite_outline;
      case 'X-Ray':
      case 'CT Scan':
      case 'MRI':
      case 'Ultrasound':
        return Icons.medical_information_outlined;
      default:
        return Icons.document_scanner_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final tt = theme.textTheme;
    final studiesAsync = ref.watch(diagnosticStudiesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Diagnostic Studies',
                style: tt.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SearchBar(
                controller: _searchCtrl,
                hintText: 'Search studies…',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  ValueListenableBuilder(
                    valueListenable: _searchCtrl,
                    builder: (_, val, __) => val.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: studiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                    strokeWidth: 3,
                  ),
                ),
                error: (e, _) => _ErrorState(
                  message: friendlyError(e),
                  onRetry: () =>
                      ref.read(diagnosticStudiesProvider.notifier).refresh(),
                ),
                data: (list) {
                  final filtered = _applySearch(list);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.document_scanner_outlined,
                      title: _searchCtrl.text.isNotEmpty
                          ? 'No studies match your search'
                          : 'No diagnostic studies yet',
                      action: _searchCtrl.text.isEmpty
                          ? GradientButton(
                              onPressed: () =>
                                  context.push('/diagnostic-studies/new'),
                              icon: const Icon(Icons.add_rounded),
                              child: const Text('Add study'),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(diagnosticStudiesProvider.notifier).refresh(),
                    color: glass.gradientStart,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _StudyCard(
                        study: filtered[i],
                        studyIcon: _studyIcon(filtered[i].studyType),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/diagnostic-studies/new'),
        tooltip: 'Add study',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.study, required this.studyIcon});

  final DiagnosticStudy study;
  final IconData studyIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final tt = theme.textTheme;
    final dateFmt = DateFormat('MMM d, yyyy');

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/diagnostic-studies/${study.id}'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: glass.glass2,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: glass.glassBorder),
            ),
            child: Icon(studyIcon, size: 22, color: glass.gradientStart),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        study.bodyRegion != null
                            ? '${study.studyType} – '
                                  '${study.bodyRegion}'
                            : study.studyType,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (study.hasAttachment)
                      Icon(
                        Icons.attach_file_rounded,
                        size: 16,
                        color: glass.gradientStart,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  study.patientName,
                  style: tt.bodySmall?.copyWith(color: glass.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFmt.format(study.studyDate),
                  style: tt.bodySmall?.copyWith(color: glass.muted2),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: glass.muted2),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load studies',
          description: message,
          action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
    );
  }
}
