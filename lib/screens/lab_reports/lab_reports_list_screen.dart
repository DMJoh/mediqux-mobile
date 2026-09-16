import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report.dart';
import 'package:mediqux_mobile/providers/lab_report_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

class LabReportsListScreen extends ConsumerStatefulWidget {
  const LabReportsListScreen({super.key});

  @override
  ConsumerState<LabReportsListScreen> createState() =>
      _LabReportsListScreenState();
}

class _LabReportsListScreenState extends ConsumerState<LabReportsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LabReport> _applySearch(List<LabReport> items) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((r) {
      return r.testName.toLowerCase().contains(q) ||
          r.patientName.toLowerCase().contains(q);
    }).toList();
  }

  Color _statusColor(BuildContext context, String? status) {
    final cs = Theme.of(context).colorScheme;
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return cs.primary;
      case 'cancelled':
        return cs.onSurfaceVariant;
      default:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final tt = theme.textTheme;
    final reportsAsync = ref.watch(labReportsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Lab Reports',
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
                hintText: 'Search lab reports…',
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
              child: reportsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                    strokeWidth: 3,
                  ),
                ),
                error: (e, _) => _ErrorState(
                  message: friendlyError(e),
                  onRetry: () =>
                      ref.read(labReportsProvider.notifier).refresh(),
                ),
                data: (list) {
                  final filtered = _applySearch(list);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.science_outlined,
                      title: _searchCtrl.text.isNotEmpty
                          ? 'No lab reports match your search'
                          : 'No lab reports yet',
                      action: _searchCtrl.text.isEmpty
                          ? GradientButton(
                              onPressed: () => context.push('/lab-reports/new'),
                              icon: const Icon(Icons.add_rounded),
                              child: const Text('Add lab report'),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(labReportsProvider.notifier).refresh(),
                    color: glass.gradientStart,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _LabReportCard(
                        report: filtered[i],
                        statusColor: _statusColor(
                          context,
                          filtered[i].testType,
                        ),
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
        onPressed: () => context.push('/lab-reports/new'),
        tooltip: 'Add lab report',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _LabReportCard extends StatelessWidget {
  const _LabReportCard({required this.report, required this.statusColor});

  final LabReport report;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final tt = theme.textTheme;
    final dateFmt = DateFormat('MMM d, yyyy');

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/lab-reports/${report.id}'),
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
            child: Icon(
              Icons.science_outlined,
              size: 22,
              color: glass.gradientStart,
            ),
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
                        report.testName,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (report.hasFile)
                      Icon(
                        Icons.attach_file_rounded,
                        size: 16,
                        color: glass.gradientStart,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  report.patientName,
                  style: tt.bodySmall?.copyWith(color: glass.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFmt.format(report.testDate),
                  style: tt.bodySmall?.copyWith(color: glass.muted2),
                ),
              ],
            ),
          ),
          if (report.testType != null) ...[
            const SizedBox(width: 8),
            StatusBadge(label: report.testType!, color: statusColor),
          ],
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
          title: 'Failed to load lab reports',
          description: message,
          action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
    );
  }
}
