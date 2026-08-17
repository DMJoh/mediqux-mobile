import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/medication/medication.dart';
import 'package:mediqux_mobile/providers/medication_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/detail_hero.dart';

class MedicationDetailScreen extends ConsumerWidget {
  const MedicationDetailScreen({required this.medicationId, super.key});

  final String medicationId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medication?'),
        content: Text(
          'Delete "${medication.name}"? '
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
      await ref.read(medicationsProvider.notifier).delete(medication.id);
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
    final tt = Theme.of(context).textTheme;
    final medicationAsync = ref.watch(medicationDetailProvider(medicationId));

    return Scaffold(
      backgroundColor: cs.surface,
      body: medicationAsync.when(
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
        data: (medication) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DetailHero(
                  title: medication.name,
                  onBack: () => context.pop(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: 'Edit',
                      onPressed: () =>
                          context.push('/medications/${medication.id}/edit'),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (v) {
                        if (v == 'delete') {
                          _confirmDelete(context, ref, medication);
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
                      _InfoSection(
                        title: 'Drug Info',
                        rows: [
                          if (medication.genericName != null)
                            _InfoRow(
                              icon: Icons.science_rounded,
                              label: 'Generic',
                              value: medication.genericName!,
                            ),
                          if (medication.manufacturer != null)
                            _InfoRow(
                              icon: Icons.factory_rounded,
                              label: 'Manufacturer',
                              value: medication.manufacturer!,
                            ),
                          _InfoRow(
                            icon: Icons.bar_chart_rounded,
                            label: 'Prescriptions',
                            value: '${medication.prescriptionCount}',
                          ),
                          _InfoRow(
                            icon: Icons.people_rounded,
                            label: 'Patients',
                            value: '${medication.patientMedicationCount}',
                          ),
                        ],
                      ),
                      if (medication.description != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                medication.description!,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (medication.dosageForms.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ChipsSection(
                          title: 'Dosage Forms',
                          items: medication.dosageForms,
                        ),
                      ],
                      if (medication.strengths.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ChipsSection(
                          title: 'Strengths',
                          items: medication.strengths,
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

class _ChipsSection extends StatelessWidget {
  const _ChipsSection({required this.title, required this.items});

  final String title;
  final List<String> items;

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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      item,
                      style: tt.labelMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
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
            width: 90,
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
