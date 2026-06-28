import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({required this.patientId, super.key});

  final String patientId;

  static const _palette = [
    Color(0xFF2196F3),
    Color(0xFF43A047),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFF00ACC1),
    Color(0xFFFFB300),
  ];

  Color _avatarColor(String name) {
    final sum = name.codeUnits.fold(0, (a, b) => a + b);
    return _palette[sum % _palette.length];
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete patient?'),
        content: const Text('This cannot be undone.'),
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
    if (confirmed != true) return;
    await ref.read(patientsProvider.notifier).delete(patient.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final patientAsync = ref.watch(patientDetailProvider(patientId));

    return Scaffold(
      backgroundColor: cs.surface,
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(e.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
        data: (patient) {
          final color = _avatarColor(patient.fullName);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: BackButton(
                  color: Colors.white,
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    tooltip: 'Edit',
                    onPressed: () =>
                        context.push('/patients/${patient.id}/edit'),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                    onSelected: (v) {
                      if (v == 'delete') {
                        _confirmDelete(context, ref, patient);
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
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    patient.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.headerGradient,
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: color.withValues(alpha: 0.25),
                        child: Text(
                          patient.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoSection(
                        title: 'Personal Information',
                        rows: [
                          _InfoRow(
                            label: 'Date of Birth',
                            value: _formatDob(patient.dateOfBirth),
                          ),
                          _InfoRow(
                            label: 'Age',
                            value: patient.age != null
                                ? '${patient.age} years old'
                                : '-',
                          ),
                          _InfoRow(
                            label: 'Gender',
                            value: patient.gender ?? '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Contact',
                        rows: [
                          _InfoRow(label: 'Phone', value: patient.phone ?? '-'),
                          _InfoRow(label: 'Email', value: patient.email ?? '-'),
                        ],
                      ),
                      if (patient.address != null &&
                          patient.address!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Address',
                          rows: [
                            _InfoRow(label: 'Address', value: patient.address!),
                          ],
                        ),
                      ],
                      if (patient.emergencyContactName != null ||
                          patient.emergencyContactPhone != null) ...[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Emergency Contact',
                          rows: [
                            _InfoRow(
                              label: 'Name',
                              value: patient.emergencyContactName ?? '-',
                            ),
                            _InfoRow(
                              label: 'Phone',
                              value: patient.emergencyContactPhone ?? '-',
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

  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return '-';
    final dt = DateTime.tryParse(dob);
    if (dt == null) return dob;
    return DateFormat('MMM d, yyyy').format(dt);
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
  const _InfoRow({required this.label, required this.value});

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
          SizedBox(
            width: 120,
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
