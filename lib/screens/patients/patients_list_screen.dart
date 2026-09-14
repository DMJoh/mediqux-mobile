import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_avatar.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';

class PatientsListScreen extends ConsumerStatefulWidget {
  const PatientsListScreen({super.key});

  @override
  ConsumerState<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends ConsumerState<PatientsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> _applySearch(List<Patient> patients) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return patients;
    return patients.where((p) {
      return p.firstName.toLowerCase().contains(query) ||
          p.lastName.toLowerCase().contains(query) ||
          (p.phone?.toLowerCase().contains(query) ?? false) ||
          (p.email?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final patientsAsync = ref.watch(patientsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Patients',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search patients…',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  ValueListenableBuilder(
                    valueListenable: _searchController,
                    builder: (_, val, __) => val.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
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
              child: patientsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                    strokeWidth: 3,
                  ),
                ),
                error: (e, _) => _ErrorState(
                  message: friendlyError(e),
                  onRetry: () => ref.read(patientsProvider.notifier).refresh(),
                ),
                data: (patients) {
                  final filtered = _applySearch(patients);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.people_outline_rounded,
                      title: _searchController.text.isNotEmpty
                          ? 'No patients match your search'
                          : 'No patients yet',
                      action: _searchController.text.isEmpty
                          ? GradientButton(
                              onPressed: () => context.push('/patients/new'),
                              icon: const Icon(Icons.add_rounded),
                              child: const Text('Add your first patient'),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(patientsProvider.notifier).refresh(),
                    color: glass.gradientStart,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _PatientCard(patient: filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/patients/new'),
        tooltip: 'Add patient',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;

    final ageLine = [
      if (patient.age != null) '${patient.age} yrs',
      if (patient.gender != null) patient.gender!,
    ].join(' · ');

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/patients/${patient.id}'),
      child: Row(
        children: [
          GradientAvatar(initials: patient.initials),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ageLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ageLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: glass.muted,
                    ),
                  ),
                ],
                if (patient.phone != null || patient.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    patient.phone ?? patient.email ?? '',
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
          title: 'Failed to load patients',
          description: message,
          action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
    );
  }
}
