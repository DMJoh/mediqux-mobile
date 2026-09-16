import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

// Returns icon and color for a given institution type.
IconData institutionIcon(String? type) {
  switch (type?.toLowerCase()) {
    case 'hospital':
      return Icons.local_hospital_rounded;
    case 'clinic':
      return Icons.medical_services_rounded;
    case 'laboratory':
      return Icons.science_rounded;
    case 'pharmacy':
      return Icons.medication_rounded;
    case 'diagnostic center':
      return Icons.biotech_rounded;
    case 'nursing home':
      return Icons.elderly_rounded;
    default:
      return Icons.business_rounded;
  }
}

Color institutionColor(String? type) {
  switch (type?.toLowerCase()) {
    case 'hospital':
      return const Color(0xFFEF5350);
    case 'clinic':
      return const Color(0xFF2196F3);
    case 'laboratory':
      return const Color(0xFFAB47BC);
    case 'pharmacy':
      return const Color(0xFF43A047);
    case 'diagnostic center':
      return const Color(0xFFFF7043);
    case 'nursing home':
      return const Color(0xFF00ACC1);
    default:
      return const Color(0xFF607D8B);
  }
}

class InstitutionsListScreen extends ConsumerStatefulWidget {
  const InstitutionsListScreen({super.key});

  @override
  ConsumerState<InstitutionsListScreen> createState() =>
      _InstitutionsListScreenState();
}

class _InstitutionsListScreenState
    extends ConsumerState<InstitutionsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Institution> _applySearch(List<Institution> institutions) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return institutions;
    return institutions.where((i) {
      return i.name.toLowerCase().contains(q) ||
          (i.type?.toLowerCase().contains(q) ?? false) ||
          (i.address?.toLowerCase().contains(q) ?? false) ||
          (i.phone?.contains(q) ?? false) ||
          (i.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final institutionsAsync = ref.watch(institutionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Institutions',
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
                hintText: 'Search institutions…',
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
              child: institutionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                    strokeWidth: 3,
                  ),
                ),
                error: (e, _) => _ErrorState(
                  message: friendlyError(e),
                  onRetry: () =>
                      ref.read(institutionsProvider.notifier).refresh(),
                ),
                data: (list) {
                  final filtered = _applySearch(list);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.business_outlined,
                      title: _searchCtrl.text.isNotEmpty
                          ? 'No institutions match your search'
                          : 'No institutions yet',
                      action: _searchCtrl.text.isEmpty
                          ? GradientButton(
                              onPressed: () =>
                                  context.push('/institutions/new'),
                              icon: const Icon(Icons.add_rounded),
                              child: const Text('Add your first institution'),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(institutionsProvider.notifier).refresh(),
                    color: glass.gradientStart,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _InstitutionCard(institution: filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/institutions/new'),
        tooltip: 'Add institution',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  const _InstitutionCard({required this.institution});

  final Institution institution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final color = institutionColor(institution.type);
    final icon = institutionIcon(institution.type);
    final dc = institution.doctorCount;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/institutions/${institution.id}'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (institution.type != null) ...[
                      StatusBadge(label: institution.type!, color: color),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.person_rounded, size: 13, color: glass.muted2),
                    const SizedBox(width: 3),
                    Text(
                      '$dc doctor${dc != 1 ? 's' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: glass.muted2,
                      ),
                    ),
                  ],
                ),
                if (institution.phone != null ||
                    institution.address != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    institution.phone ?? institution.address ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: glass.muted2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
          title: 'Failed to load institutions',
          description: message,
          action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
    );
  }
}
