import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/prescription/prescription.dart';
import 'package:mediqux_mobile/providers/prescription_provider.dart';
import 'package:mediqux_mobile/widgets/app_drawer.dart';

class PrescriptionsListScreen extends ConsumerStatefulWidget {
  const PrescriptionsListScreen({super.key});

  @override
  ConsumerState<PrescriptionsListScreen> createState() =>
      _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState
    extends ConsumerState<PrescriptionsListScreen> {
  bool _isSearching = false;
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

  Color _statusColor(BuildContext context, String? status) {
    final cs = Theme.of(context).colorScheme;
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'discontinued':
        return cs.onSurfaceVariant;
      case 'completed':
        return cs.primary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rxAsync = ref.watch(prescriptionsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      drawer: const AppDrawer(currentRoute: '/prescriptions'),
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
                  hintText: 'Search prescriptions...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(
                'Prescriptions',
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
        onRefresh: () => ref.read(prescriptionsProvider.notifier).refresh(),
        color: cs.primary,
        child: rxAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: _ErrorState(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(prescriptionsProvider.notifier).refresh(),
                ),
              ),
            ],
          ),
          data: (list) {
            final filtered = _applySearch(list);
            if (filtered.isEmpty) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    child: _EmptyState(
                      hasSearch: _searchCtrl.text.isNotEmpty,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _PrescriptionCard(
                rx: filtered[i],
                statusColor: _statusColor(context, filtered[i].status),
              ),
            );
          },
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
  const _PrescriptionCard({required this.rx, required this.statusColor});

  final Prescription rx;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => context.push('/prescriptions/${rx.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  size: 22,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rx.medicationDisplay,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rx.patientName,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rx.dosage} · ${rx.frequency}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (rx.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(
                    rx.status!,
                    style: tt.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                Icons.medication_rounded,
                size: 40,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch
                  ? 'No prescriptions match your search'
                  : 'No prescriptions yet',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (!hasSearch)
              FilledButton.icon(
                onPressed: () => context.push('/prescriptions/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add prescription'),
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
              'Failed to load prescriptions',
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
