import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/condition/condition.dart';
import 'package:mediqux_mobile/providers/condition_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/glass_app_header.dart';
import 'package:mediqux_mobile/widgets/info_section.dart';
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

class ConditionDetailScreen extends ConsumerWidget {
  const ConditionDetailScreen({required this.conditionId, super.key});

  final String conditionId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Condition condition,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete condition?'),
        content: Text(
          'Delete "${condition.name}"? '
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
      await ref.read(conditionsProvider.notifier).delete(condition.id);
      if (context.mounted) context.pop();
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final conditionAsync = ref.watch(conditionDetailProvider(conditionId));

    return Scaffold(
      body: conditionAsync.when(
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
        data: (condition) {
          final chips = [if (condition.category != null) condition.category!];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GlassAppHeader(
                  title: condition.name,
                  chips: chips,
                  onBack: () => context.pop(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () =>
                          context.push('/conditions/${condition.id}/edit'),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (v) {
                        if (v == 'delete') {
                          _confirmDelete(context, ref, condition);
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
                      if (condition.severity != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge.tone(
                            context,
                            label: condition.severity!,
                            tone: _severityTone(condition.severity),
                          ),
                        ),
                      if (condition.severity != null)
                        const SizedBox(height: 12),
                      InfoSection(
                        title: 'Details',
                        rows: [
                          if (condition.icdCode != null)
                            InfoRow(
                              label: 'ICD Code',
                              value: condition.icdCode!,
                            ),
                          InfoRow(
                            label: 'Usage',
                            value:
                                '${condition.usageCount} patient'
                                '${condition.usageCount != 1 ? 's' : ''}',
                          ),
                        ],
                      ),
                      if (condition.description != null) ...[
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Description',
                          rows: [
                            InfoRow(
                              label: 'Description',
                              value: condition.description!,
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
          );
        },
      ),
    );
  }
}
