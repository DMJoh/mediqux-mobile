import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/condition/condition.dart';
import 'package:mediqux_mobile/providers/condition_provider.dart';
import 'package:mediqux_mobile/widgets/app_drawer.dart';

Color _severityColor(String? severity) {
  switch (severity?.toLowerCase()) {
    case 'low':
      return const Color(0xFF43A047);
    case 'medium':
      return const Color(0xFFFF7043);
    case 'high':
      return const Color(0xFFEF5350);
    default:
      return const Color(0xFF607D8B);
  }
}

class ConditionsListScreen extends ConsumerStatefulWidget {
  const ConditionsListScreen({super.key});

  @override
  ConsumerState<ConditionsListScreen> createState() =>
      _ConditionsListScreenState();
}

class _ConditionsListScreenState extends ConsumerState<ConditionsListScreen> {
  bool _isSearching = false;
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
    final cs = Theme.of(context).colorScheme;
    final conditionsAsync = ref.watch(conditionsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      drawer: const AppDrawer(currentRoute: '/conditions'),
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
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search conditions...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(
                'Conditions',
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
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(conditionsProvider.notifier).refresh(),
        color: cs.primary,
        child: conditionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: _ErrorState(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(conditionsProvider.notifier).refresh(),
                ),
              ),
            ),
          ),
          data: (list) {
            final filtered = _applySearch(list);
            if (filtered.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: _EmptyState(hasSearch: _searchCtrl.text.isNotEmpty),
                  ),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ConditionCard(condition: filtered[i]),
            );
          },
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final severityColor = _severityColor(condition.severity);

    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => context.push('/conditions/${condition.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                child: Icon(
                  Icons.healing_rounded,
                  color: cs.onPrimaryContainer,
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
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (condition.icdCode != null) ...[
                          Text(
                            condition.icdCode!,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (condition.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Text(
                              condition.category!,
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (condition.severity != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: severityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            condition.severity!,
                            style: tt.labelSmall?.copyWith(
                              color: severityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
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
                Icons.healing_rounded,
                size: 40,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch
                  ? 'No conditions match your search'
                  : 'No conditions yet',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (!hasSearch)
              FilledButton.icon(
                onPressed: () => context.push('/conditions/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add condition'),
              ),
          ],
        ),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load conditions',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
