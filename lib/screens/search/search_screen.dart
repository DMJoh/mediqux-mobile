import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/providers/condition_provider.dart';
import 'package:mediqux_mobile/providers/diagnostic_study_provider.dart';
import 'package:mediqux_mobile/providers/doctor_provider.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';
import 'package:mediqux_mobile/providers/lab_report_provider.dart';
import 'package:mediqux_mobile/providers/medication_provider.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';
import 'package:mediqux_mobile/providers/prescription_provider.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_avatar.dart';

class _Hit {
  const _Hit({
    required this.title,
    required this.route,
    this.subtitle,
    this.avatarInitials,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String route;

  /// Patients/Doctors show a [GradientAvatar]; everything else shows [icon]
  /// in a flat glass chip.
  final String? avatarInitials;
  final IconData? icon;
}

class _HitGroup {
  const _HitGroup({
    required this.label,
    required this.icon,
    required this.hits,
  });

  final String label;
  final IconData icon;
  final List<_Hit> hits;
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _matches(String query, Iterable<String?> fields) {
    final q = query.toLowerCase();
    return fields.any((f) => (f ?? '').toLowerCase().contains(q));
  }

  List<_HitGroup> _buildGroups(String query) {
    final groups = <_HitGroup>[];

    final patients = ref.watch(patientsProvider).value ?? [];
    final patientHits = patients
        .where((p) => _matches(query, [p.fullName, p.phone, p.email]))
        .take(6)
        .map(
          (p) => _Hit(
            title: p.fullName,
            subtitle: [
              if (p.age != null) '${p.age} yrs',
              if (p.gender != null) p.gender,
            ].whereType<String>().join(' · '),
            avatarInitials: p.initials,
            route: '/patients/${p.id}',
          ),
        )
        .toList();
    if (patientHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Patients',
          icon: Icons.people_outline_rounded,
          hits: patientHits,
        ),
      );
    }

    final appointments = ref.watch(appointmentsProvider).value ?? [];
    final apptHits = appointments
        .where((a) => _matches(query, [a.patientName, a.doctorName, a.type]))
        .take(6)
        .map(
          (a) => _Hit(
            title: '${a.patientName} · ${a.type ?? 'Appointment'}',
            subtitle: a.doctorName,
            icon: Icons.calendar_month_outlined,
            route: '/appointments/${a.id}',
          ),
        )
        .toList();
    if (apptHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Appointments',
          icon: Icons.calendar_month_outlined,
          hits: apptHits,
        ),
      );
    }

    final doctors = ref.watch(doctorsProvider).value ?? [];
    final doctorHits = doctors
        .where((d) => _matches(query, [d.fullName, d.specialty]))
        .take(6)
        .map(
          (d) => _Hit(
            title: d.fullName,
            subtitle: d.specialty,
            avatarInitials: d.initials,
            route: '/doctors/${d.id}',
          ),
        )
        .toList();
    if (doctorHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Doctors',
          icon: Icons.medical_services_outlined,
          hits: doctorHits,
        ),
      );
    }

    final institutions = ref.watch(institutionsProvider).value ?? [];
    final institutionHits = institutions
        .where((i) => _matches(query, [i.name, i.type]))
        .take(6)
        .map(
          (i) => _Hit(
            title: i.name,
            subtitle: i.type,
            icon: Icons.business_outlined,
            route: '/institutions/${i.id}',
          ),
        )
        .toList();
    if (institutionHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Institutions',
          icon: Icons.business_outlined,
          hits: institutionHits,
        ),
      );
    }

    final conditions = ref.watch(conditionsProvider).value ?? [];
    final conditionHits = conditions
        .where((c) => _matches(query, [c.name, c.category]))
        .take(6)
        .map(
          (c) => _Hit(
            title: c.name,
            subtitle: c.category,
            icon: Icons.health_and_safety_outlined,
            route: '/conditions/${c.id}',
          ),
        )
        .toList();
    if (conditionHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Conditions',
          icon: Icons.health_and_safety_outlined,
          hits: conditionHits,
        ),
      );
    }

    final medications = ref.watch(medicationsProvider).value ?? [];
    final medicationHits = medications
        .where((m) => _matches(query, [m.name, m.genericName]))
        .take(6)
        .map(
          (m) => _Hit(
            title: m.name,
            subtitle: m.genericName,
            icon: Icons.medication_outlined,
            route: '/medications/${m.id}',
          ),
        )
        .toList();
    if (medicationHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Medications',
          icon: Icons.medication_outlined,
          hits: medicationHits,
        ),
      );
    }

    final prescriptions = ref.watch(prescriptionsProvider).value ?? [];
    final prescriptionHits = prescriptions
        .where(
          (p) => _matches(query, [
            p.medicationName,
            '${p.patientFirstName ?? ''} ${p.patientLastName ?? ''}',
          ]),
        )
        .take(6)
        .map(
          (p) => _Hit(
            title: p.medicationName ?? 'Prescription',
            subtitle: '${p.patientFirstName ?? ''} ${p.patientLastName ?? ''}'
                .trim(),
            icon: Icons.receipt_long_outlined,
            route: '/prescriptions/${p.id}',
          ),
        )
        .toList();
    if (prescriptionHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Prescriptions',
          icon: Icons.receipt_long_outlined,
          hits: prescriptionHits,
        ),
      );
    }

    final labReports = ref.watch(labReportsProvider).value ?? [];
    final labReportHits = labReports
        .where((l) => _matches(query, [l.testName, l.patientName]))
        .take(6)
        .map(
          (l) => _Hit(
            title: l.testName,
            subtitle: l.patientName,
            icon: Icons.science_outlined,
            route: '/lab-reports/${l.id}',
          ),
        )
        .toList();
    if (labReportHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Lab Reports',
          icon: Icons.science_outlined,
          hits: labReportHits,
        ),
      );
    }

    final studies = ref.watch(diagnosticStudiesProvider).value ?? [];
    final studyHits = studies
        .where((s) => _matches(query, [s.studyType, s.patientName]))
        .take(6)
        .map(
          (s) => _Hit(
            title: s.studyType,
            subtitle: s.patientName,
            icon: Icons.image_search_outlined,
            route: '/diagnostic-studies/${s.id}',
          ),
        )
        .toList();
    if (studyHits.isNotEmpty) {
      groups.add(
        _HitGroup(
          label: 'Diagnostic Studies',
          icon: Icons.image_search_outlined,
          hits: studyHits,
        ),
      );
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final query = _controller.text.trim();
    final groups = query.length >= 2 ? _buildGroups(query) : <_HitGroup>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: SearchBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      hintText: 'Search patients, doctors, records…',
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (_, val, __) => val.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {});
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: query.length < 2
                  ? const EmptyStateView(
                      icon: Icons.search_rounded,
                      title: 'Search everything',
                      description:
                          'Find a patient, appointment, doctor, or any '
                          'other record by name.',
                    )
                  : groups.isEmpty
                  ? EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: 'No matches for "$query"',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      children: [
                        for (final group in groups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                            child: Text(
                              group.label.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: glass.muted2,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Column(
                              children: [
                                for (final hit in group.hits) _HitRow(hit: hit),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit});

  final _Hit hit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      onTap: () => context.push(hit.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            if (hit.avatarInitials != null)
              GradientAvatar(initials: hit.avatarInitials!, size: 34)
            else
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: glass.glass2,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(hit.icon, size: 17, color: glass.muted),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hit.subtitle != null && hit.subtitle!.isNotEmpty)
                    Text(
                      hit.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: glass.muted2,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
