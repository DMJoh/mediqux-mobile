import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/glass_app_header.dart';
import 'package:mediqux_mobile/widgets/info_section.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({required this.patientId, super.key});

  final String patientId;

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
      body: patientAsync.when(
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
        data: (patient) {
          final chips = [
            if (patient.age != null) '${patient.age} yrs',
            if (patient.gender != null && patient.gender!.isNotEmpty)
              patient.gender!,
          ];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GlassAppHeader(
                  title: patient.fullName,
                  avatarText: patient.initials,
                  chips: chips,
                  onBack: () => context.pop(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () =>
                          context.push('/patients/${patient.id}/edit'),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
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
                      InfoSection(
                        title: 'Personal',
                        rows: [
                          InfoRow(
                            label: 'Date of Birth',
                            value: _formatDob(patient.dateOfBirth),
                          ),
                          InfoRow(
                            label: 'Age',
                            value: patient.age != null
                                ? '${patient.age} years old'
                                : '-',
                          ),
                          InfoRow(
                            label: 'Gender',
                            value: patient.gender ?? '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InfoSection(
                        title: 'Contact',
                        rows: [
                          InfoRow(label: 'Phone', value: patient.phone ?? '-'),
                          InfoRow(label: 'Email', value: patient.email ?? '-'),
                        ],
                      ),
                      if (patient.address != null &&
                          patient.address!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Address',
                          rows: [
                            InfoRow(label: 'Address', value: patient.address!),
                          ],
                        ),
                      ],
                      if (patient.emergencyContactName != null ||
                          patient.emergencyContactPhone != null) ...[
                        const SizedBox(height: 12),
                        InfoSection(
                          title: 'Emergency',
                          rows: [
                            InfoRow(
                              label: 'Name',
                              value: patient.emergencyContactName ?? '-',
                            ),
                            InfoRow(
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
