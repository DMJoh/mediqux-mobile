import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/config/theme.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/models/dashboard/appointment_stats.dart';
import 'package:mediqux_mobile/models/dashboard/upcoming_appointment.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/dashboard_provider.dart';
import 'package:mediqux_mobile/providers/doctor_provider.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/empty_state_view.dart';
import 'package:mediqux_mobile/widgets/glass_card.dart';
import 'package:mediqux_mobile/widgets/gradient_avatar.dart';
import 'package:mediqux_mobile/widgets/mediqux_logo.dart';
import 'package:mediqux_mobile/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(upcomingAppointmentsProvider)
      ..invalidate(appointmentStatsProvider)
      ..invalidate(patientsProvider)
      ..invalidate(doctorsProvider)
      ..invalidate(appointmentsProvider);
    await Future.wait([
      ref.read(upcomingAppointmentsProvider.future),
      ref.read(appointmentStatsProvider.future),
      ref.read(patientsProvider.future),
      ref.read(doctorsProvider.future),
      ref.read(appointmentsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    final user = ref.watch(authProvider).value;
    final statsAsync = ref.watch(appointmentStatsProvider);
    final patientsAsync = ref.watch(patientsProvider);
    final doctorsAsync = ref.watch(doctorsProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final apptAsync = ref.watch(upcomingAppointmentsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        color: glass.gradientStart,
        child: CustomScrollView(
          slivers: [
            _DashboardHeader(
              greeting: _greeting(),
              firstName: user?.firstName ?? '',
            ),
            SliverToBoxAdapter(
              child: apptAsync.maybeWhen(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : _NextAppointmentHero(appointment: list.first),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: patientsAsync.maybeWhen(
                data: (patients) => patients.isEmpty
                    ? const SizedBox.shrink()
                    : _PatientRosterStrip(
                        patients: patients,
                        upcoming: apptAsync.value ?? const [],
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: _QuickActionsRow()),
            SliverToBoxAdapter(
              child: _StatsGrid(
                statsAsync: statsAsync,
                patientsAsync: patientsAsync,
                doctorsAsync: doctorsAsync,
              ),
            ),
            SliverToBoxAdapter(
              child: appointmentsAsync.maybeWhen(
                data: (list) => _AppointmentsTrendCard(appointments: list),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: appointmentsAsync.maybeWhen(
                data: (list) => _RecentActivitySection(appointments: list),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: glass.gradientStart,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upcoming Appointments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _AppointmentsSliver(apptAsync: apptAsync),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.greeting, required this.firstName});

  final String greeting;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final glass = Theme.of(context).extension<GlassColors>()!;
    final dateStr = DateFormat('EEE, MMM d').format(DateTime.now());

    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const MediquxLogo(size: 52),
                  const SizedBox(width: 12),
                  Text(
                    'Mediqux',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                dateStr,
                style: AppTheme.monoStyle(
                  color: glass.muted2,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                firstName.isNotEmpty ? '$greeting,\n$firstName' : '$greeting!',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A prominent hero card spotlighting the single soonest appointment, with
/// a gradient "days until" figure — mirrors the web dashboard's headline
/// stat treatment.
class _NextAppointmentHero extends StatelessWidget {
  const _NextAppointmentHero({required this.appointment});

  final UpcomingAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final now = DateTime.now();
    final date = appointment.appointmentDate;
    final dayDiff = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    final String bigLabel;
    final String subLabel;
    if (dayDiff <= 0) {
      bigLabel = 'Today';
      subLabel = DateFormat.jm().format(date);
    } else if (dayDiff == 1) {
      bigLabel = 'Tomorrow';
      subLabel = DateFormat.jm().format(date);
    } else {
      bigLabel = '${dayDiff}d';
      subLabel = DateFormat('EEE, MMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GlassCard(
        onTap: () => context.push('/appointments/${appointment.id}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT APPOINTMENT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: glass.gradientStart,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appointment.patientName.isNotEmpty
                        ? appointment.patientName
                        : 'Unknown patient',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (appointment.doctorName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Dr. ${appointment.doctorName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: glass.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    subLabel,
                    style: AppTheme.monoStyle(color: glass.muted2),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 84),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      glass.accentGradient.createShader(bounds),
                  child: Text(
                    bigLabel,
                    maxLines: 1,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally-scrollable roster of patients (avatar, name, next
/// appointment date if any) with a trailing "Add patient" card — mirrors
/// the web dashboard's "Your patients" strip.
class _PatientRosterStrip extends StatelessWidget {
  const _PatientRosterStrip({required this.patients, required this.upcoming});

  final List<Patient> patients;
  final List<UpcomingAppointment> upcoming;

  String? _nextApptLabel(Patient p) {
    for (final a in upcoming) {
      if (a.patientName.toLowerCase() == p.fullName.toLowerCase()) {
        return DateFormat('MMM d').format(a.appointmentDate);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final shown = patients.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your Patients',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/patients'),
                child: Text(
                  'View all',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: glass.gradientEnd,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: shown.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (i == shown.length) {
                return _AddPatientCard(glass: glass);
              }
              final patient = shown[i];
              final next = _nextApptLabel(patient);
              return SizedBox(
                width: 92,
                child: GlassCard(
                  nested: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                  onTap: () => context.push('/patients/${patient.id}'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GradientAvatar(initials: patient.initials, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        patient.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        next ?? 'No upcoming',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTheme.monoStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: next != null
                              ? glass.gradientEnd
                              : glass.muted2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddPatientCard extends StatelessWidget {
  const _AddPatientCard({required this.glass});

  final GlassColors glass;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: GlassCard(
        nested: true,
        onTap: () => context.push('/patients/new'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: glass.gradientStart, size: 26),
            const SizedBox(height: 8),
            Text(
              'Add patient',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: glass.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

/// Evenly-spaced row of common "add" shortcuts — deliberately excludes
/// "Add Patient" since that's already offered at the end of the patient
/// roster strip directly above.
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  static const _actions = [
    _QuickAction(
      icon: Icons.event_available_outlined,
      label: 'Add Appointment',
      route: '/appointments/new',
    ),
    _QuickAction(
      icon: Icons.receipt_long_outlined,
      label: 'Add Prescription',
      route: '/prescriptions/new',
    ),
    _QuickAction(
      icon: Icons.science_outlined,
      label: 'Add Lab Report',
      route: '/lab-reports/new',
    ),
    _QuickAction(
      icon: Icons.medication_outlined,
      label: 'Add Medication',
      route: '/medications/new',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < _actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(action: _actions[i], glass: glass),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.glass});

  final _QuickAction action;
  final GlassColors glass;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: GlassCard(
        nested: true,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        onTap: () => context.push(action.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 22, color: glass.gradientStart),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.statsAsync,
    required this.patientsAsync,
    required this.doctorsAsync,
  });

  final AsyncValue<AppointmentStats> statsAsync;
  final AsyncValue<List<Patient>> patientsAsync;
  final AsyncValue<List<Doctor>> doctorsAsync;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.1,
        children: [
          _StatCard(
            icon: Icons.people_alt_outlined,
            label: 'Patients',
            value: patientsAsync.when(
              data: (v) => '${v.length}',
              loading: () => '—',
              error: (_, __) => '!',
            ),
          ),
          _StatCard(
            icon: Icons.medical_services_outlined,
            label: 'Doctors',
            value: doctorsAsync.when(
              data: (v) => '${v.length}',
              loading: () => '—',
              error: (_, __) => '!',
            ),
          ),
          _StatCard(
            icon: Icons.today_outlined,
            label: 'Today',
            value: statsAsync.when(
              data: (s) => '${s.today}',
              loading: () => '—',
              error: (_, __) => '!',
            ),
          ),
          _StatCard(
            icon: Icons.check_circle_outline,
            label: 'Completed',
            value: statsAsync.when(
              data: (s) => '${s.completed}',
              loading: () => '—',
              error: (_, __) => '!',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: glass.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glass.gradientStart.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTheme.monoStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: glass.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart of appointment volume over the last 6 months, bucketed
/// client-side (the backend has no aggregation endpoint) — mirrors the
/// web dashboard's "Appointments, last 12 months" chart, scaled down for
/// a phone screen.
class _AppointmentsTrendCard extends StatelessWidget {
  const _AppointmentsTrendCard({required this.appointments});

  final List<Appointment> appointments;

  static const _months = 6;

  List<int> _bucket() {
    final now = DateTime.now();
    final counts = List<int>.filled(_months, 0);
    for (final a in appointments) {
      final d = a.appointmentDate;
      final monthsAgo = (now.year - d.year) * 12 + (now.month - d.month);
      if (monthsAgo >= 0 && monthsAgo < _months) {
        counts[_months - 1 - monthsAgo]++;
      }
    }
    return counts;
  }

  List<String> _labels() {
    final now = DateTime.now();
    return List.generate(_months, (i) {
      final monthsAgo = _months - 1 - i;
      final d = DateTime(now.year, now.month - monthsAgo);
      return DateFormat('MMM').format(d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final counts = _bucket();
    final labels = _labels();
    final maxCount = counts.fold(0, (m, c) => c > m ? c : m);
    final total = counts.fold(0, (s, c) => s + c);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointments',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Last 6 months',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: glass.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$total',
                  style: AppTheme.monoStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: glass.gradientStart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 108,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _months; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              counts[i] > 0 ? '${counts[i]}' : '',
                              style: AppTheme.monoStyle(
                                fontSize: 10,
                                color: glass.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: maxCount == 0
                                  ? 4
                                  : 8 + (counts[i] / maxCount) * 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    glass.gradientEnd,
                                    glass.gradientStart,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              labels[i],
                              style: AppTheme.monoStyle(
                                fontSize: 10,
                                color: glass.muted2,
                              ),
                            ),
                          ],
                        ),
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

/// Feed of the most recently completed/past appointments — the mobile
/// equivalent of the web dashboard's "Recent activity" list, derived
/// client-side from the appointments list (no dedicated activity-log
/// endpoint exists on the backend).
class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final now = DateTime.now();
    // `appointments` is already sorted soonest-first (descending by date),
    // so filtering to the past preserves most-recent-first order.
    final past = appointments
        .where((a) => a.appointmentDate.isBefore(now))
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_outlined, size: 18, color: glass.muted),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (past.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'No recent activity yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: glass.muted,
                  ),
                ),
              )
            else
              ...past.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    onTap: () => context.push('/appointments/${a.id}'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: glass.success,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${a.type ?? 'Appointment'} completed for '
                                '${a.patientName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'MMM d, yyyy · h:mm a',
                                ).format(a.appointmentDate),
                                style: AppTheme.monoStyle(
                                  fontSize: 10,
                                  color: glass.muted2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsSliver extends StatelessWidget {
  const _AppointmentsSliver({required this.apptAsync});

  final AsyncValue<List<UpcomingAppointment>> apptAsync;

  @override
  Widget build(BuildContext context) {
    return apptAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: CircularProgressIndicator(
              strokeCap: StrokeCap.round,
              strokeWidth: 3,
            ),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ErrorCard(message: friendlyError(e)),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyStateView(
              icon: Icons.event_available_outlined,
              title: 'No upcoming appointments',
              description: 'Pull down to refresh',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AppointmentCard(appointment: list[i]),
          ),
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final UpcomingAppointment appointment;

  static StatusTone _typeTone(String? type) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassColors>()!;
    final date = appointment.appointmentDate;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final dateLabel = isToday
        ? 'Today · ${DateFormat.jm().format(date)}'
        : DateFormat('EEE, MMM d · h:mm a').format(date);

    return GlassCard(
      nested: true,
      margin: EdgeInsets.zero,
      onTap: () => context.push('/appointments/${appointment.id}'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isToday ? glass.accentGradient : null,
              color: isToday ? null : glass.glass2,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 22,
              color: isToday ? Colors.white : glass.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName.isNotEmpty
                      ? appointment.patientName
                      : 'Unknown patient',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  dateLabel,
                  style:
                      AppTheme.monoStyle(
                        fontSize: 11,
                        color: isToday ? glass.gradientEnd : glass.muted,
                      ).copyWith(
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
                if (appointment.doctorName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Dr. ${appointment.doctorName}',
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
          const SizedBox(width: 8),
          StatusBadge.tone(
            context,
            label: appointment.type ?? '—',
            tone: _typeTone(appointment.type),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load. Pull down to retry.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
