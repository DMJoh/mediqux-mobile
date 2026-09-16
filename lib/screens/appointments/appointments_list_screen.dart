import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

StatusTone _statusTone(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return StatusTone.positive;
    case 'cancelled':
      return StatusTone.critical;
    case 'scheduled':
    default:
      return StatusTone.neutral;
  }
}

StatusTone _typeTone(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'emergency':
      return StatusTone.critical;
    case 'follow-up':
    case 'followup':
      return StatusTone.positive;
    case 'surgery':
      return StatusTone.warning;
    default:
      return StatusTone.neutral;
  }
}

class AppointmentsListScreen extends ConsumerStatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  ConsumerState<AppointmentsListScreen> createState() =>
      _AppointmentsListScreenState();
}

class _AppointmentsListScreenState
    extends ConsumerState<AppointmentsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Appointment> _applySearch(List<Appointment> items) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((a) {
      return a.patientName.toLowerCase().contains(q) ||
          (a.type?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final aptsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Appointments',
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
                hintText: 'Search appointments…',
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
              child: aptsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                    strokeWidth: 3,
                  ),
                ),
                error: (e, _) => _ErrorState(
                  message: friendlyError(e),
                  onRetry: () =>
                      ref.read(appointmentsProvider.notifier).refresh(),
                ),
                data: (list) {
                  final filtered = _applySearch(list);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.calendar_month_outlined,
                      title: _searchCtrl.text.isNotEmpty
                          ? 'No appointments match your search'
                          : 'No appointments yet',
                      action: _searchCtrl.text.isEmpty
                          ? GradientButton(
                              onPressed: () =>
                                  context.push('/appointments/new'),
                              icon: const Icon(Icons.add_rounded),
                              child: const Text('Add appointment'),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(appointmentsProvider.notifier).refresh(),
                    color: glass.gradientStart,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _AppointmentCard(appointment: filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/appointments/new'),
        tooltip: 'Add appointment',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/appointments/${appointment.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateFmt.format(appointment.appointmentDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: glass.gradientStart,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge.tone(
                context,
                label: appointment.status,
                tone: _statusTone(appointment.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            appointment.patientName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (appointment.type != null) ...[
            const SizedBox(height: 6),
            StatusBadge.tone(
              context,
              label: appointment.type!,
              tone: _typeTone(appointment.type),
            ),
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
          title: 'Failed to load appointments',
          description: message,
          action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
    );
  }
}
