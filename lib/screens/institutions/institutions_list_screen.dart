import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';
import 'package:mediqux_mobile/widgets/app_drawer.dart';

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
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Institution> _applySearch(
    List<Institution> institutions,
  ) {
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
    final cs = Theme.of(context).colorScheme;
    final institutionsAsync = ref.watch(institutionsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      drawer: const AppDrawer(currentRoute: '/institutions'),
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _isSearching = false;
                  _searchCtrl.clear();
                }),
              )
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () =>
                      Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search institutions...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(
                'Institutions',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                if (_searchCtrl.text.isEmpty) {
                  setState(() => _isSearching = false);
                } else {
                  setState(_searchCtrl.clear);
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () =>
                  setState(() => _isSearching = true),
            ),
        ],
      ),
      body: institutionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref
              .read(institutionsProvider.notifier)
              .refresh(),
        ),
        data: (list) {
          final filtered = _applySearch(list);
          if (filtered.isEmpty) {
            return _EmptyState(
              hasSearch: _searchCtrl.text.isNotEmpty,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref
                .read(institutionsProvider.notifier)
                .refresh(),
            color: cs.primary,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                96,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _InstitutionCard(institution: filtered[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/institutions/new'),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = institutionColor(institution.type);
    final icon = institutionIcon(institution.type);
    final dc = institution.doctorCount;

    return Card(
      child: InkWell(
        borderRadius:
            const BorderRadius.all(Radius.circular(16)),
        onTap: () => context
            .push('/institutions/${institution.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(14),
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      institution.name,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (institution.type != null) ...[
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  color.withValues(alpha: 0.1),
                              borderRadius:
                                  const BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              institution.type!,
                              style: tt.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.person_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$dc doctor${dc != 1 ? 's' : ''}',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (institution.phone != null ||
                        institution.address != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        institution.phone ??
                            institution.address ??
                            '',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_rounded,
                size: 40,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch
                  ? 'No institutions match your search'
                  : 'No institutions yet',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (!hasSearch)
              FilledButton.icon(
                onPressed: () =>
                    context.push('/institutions/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add institution'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: cs.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load institutions',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
