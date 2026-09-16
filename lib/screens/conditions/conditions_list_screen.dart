import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/condition/condition.dart';
import 'package:mediqux_mobile/providers/condition_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

StatusTone _severityTone(String? severity) {
  switch (severity?.toLowerCase()) {
    case 'low':
      return StatusTone.positive;
    case 'medium':
      return StatusTone.warning;
    case 'high':
      return StatusTone.critical;
    default:
      return StatusTone.neutral;
  }
}

class ConditionsListScreen extends ConsumerStatefulWidget {
  const ConditionsListScreen({super.key});

  @override
  ConsumerState<ConditionsListScreen> createState() =>
      _ConditionsListScreenState();
}

class _ConditionsListScreenState extends ConsumerState<ConditionsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Condition> _applySearch(List<Condition> conditions) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return conditions;
    return conditions.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.icdCode?.toLowerCase().contains(q) ?? false) ||
          (c.category?.toLowerCase().contains(q) ?? false) ||
          (c.severity?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final conditionsAsync = ref.watch(conditionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Conditions',
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
                hintText: 'Search conditions…',
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
              child: conditionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                    strokeWidth: 3,
                  ),
                ),
                error: (e, _) => _ErrorState(
                  message: friendlyError(e),
                  onRetry: () =>
                      ref.read(conditionsProvider.notifier).refresh(),
                ),
                data: (list) {
                  final filtered = _applySearch(list);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.healing_outlined,
                      title: _searchCtrl.text.isNotEmpty
                          ? 'No conditions match your search'
                          : 'No conditions yet',
                      action: _searchCtrl.text.isEmpty
                          ? GradientButton(
                              onPressed: () => context.push('/conditions/new'),
                              icon: const Icon(Icons.add_rounded),
                              child: const Text('Add condition'),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(conditionsProvider.notifier).refresh(),
                    color: glass.gradientStart,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _ConditionCard(condition: filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/conditions/new'),
        tooltip: 'Add condition',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.condition});

  final Condition condition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/conditions/${condition.id}'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: glass.accentGradient,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: const Icon(
              Icons.healing_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (condition.icdCode != null)
                      Text(
                        condition.icdCode!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: glass.muted2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (condition.category != null)
                      StatusBadge(
                        label: condition.category!,
                        color: glass.muted,
                      ),
                    if (condition.severity != null)
                      StatusBadge.tone(
                        context,
                        label: condition.severity!,
                        tone: _severityTone(condition.severity),
                      ),
                  ],
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
          title: 'Failed to load conditions',
          description: message,
          action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
    );
  }
}
