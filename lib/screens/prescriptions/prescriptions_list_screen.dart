import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/prescription/prescription.dart';
import 'package:mediqux_mobile/providers/prescription_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

class PrescriptionsListScreen extends ConsumerStatefulWidget {
  const PrescriptionsListScreen({super.key});

  @override
  ConsumerState<PrescriptionsListScreen> createState() =>
      _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState
    extends ConsumerState<PrescriptionsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Prescription> _applySearch(List<Prescription> items) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((p) {
      return p.patientName.toLowerCase().contains(q) ||
          p.medicationDisplay.toLowerCase().contains(q);
    }).toList();
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final rxAsync = ref.watch(prescriptionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Prescriptions',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SearchBar(
                controller: _searchCtrl,
                hintText: 'Search prescriptions…',
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
              child: rxAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                    strokeWidth: 3,
                  ),
                ),
                error: (e, _) => _ErrorState(
                  message: friendlyError(e),
                  onRetry: () =>
                      ref.read(prescriptionsProvider.notifier).refresh(),
                ),
                data: (list) {
                  final filtered = _applySearch(list);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: _searchCtrl.text.isNotEmpty
                          ? 'No prescriptions match your search'
                          : 'No prescriptions yet',
                      action: _searchCtrl.text.isEmpty
                          ? GradientButton(
                              onPressed: () =>
                                  context.push('/prescriptions/new'),
                              icon: const Icon(Icons.add_rounded),
                              child: const Text('Add prescription'),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(prescriptionsProvider.notifier).refresh(),
                    color: glass.gradientStart,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _PrescriptionCard(
                        rx: filtered[i],
                        statusTone: _statusTone(filtered[i].status),
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
        onPressed: () => context.push('/prescriptions/new'),
        tooltip: 'Add prescription',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.rx, required this.statusTone});

  final Prescription rx;
  final StatusTone statusTone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/prescriptions/${rx.id}'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: glass.accentGradient,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(
              Icons.medication_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rx.medicationDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  rx.patientName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: glass.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${rx.dosage} · ${rx.frequency}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: glass.muted2,
                  ),
                ),
              ],
            ),
          ),
          if (rx.status != null)
            StatusBadge.tone(context, label: rx.status!, tone: statusTone),
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
          title: 'Failed to load prescriptions',
          description: message,
          action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
    );
  }
}
