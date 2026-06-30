import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/user.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/screens/appointments/appointment_detail_screen.dart';
import 'package:mediqux_mobile/screens/appointments/appointment_form_screen.dart';
import 'package:mediqux_mobile/screens/appointments/appointments_list_screen.dart';
import 'package:mediqux_mobile/screens/auth/login_screen.dart';
import 'package:mediqux_mobile/screens/conditions/condition_detail_screen.dart';
import 'package:mediqux_mobile/screens/conditions/condition_form_screen.dart';
import 'package:mediqux_mobile/screens/conditions/conditions_list_screen.dart';
import 'package:mediqux_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:mediqux_mobile/screens/diagnostic_studies/diagnostic_studies_list_screen.dart';
import 'package:mediqux_mobile/screens/diagnostic_studies/diagnostic_study_detail_screen.dart';
import 'package:mediqux_mobile/screens/diagnostic_studies/diagnostic_study_form_screen.dart';
import 'package:mediqux_mobile/screens/doctors/doctor_detail_screen.dart';
import 'package:mediqux_mobile/screens/doctors/doctor_form_screen.dart';
import 'package:mediqux_mobile/screens/doctors/doctors_list_screen.dart';
import 'package:mediqux_mobile/screens/institutions/institution_detail_screen.dart';
import 'package:mediqux_mobile/screens/institutions/institution_form_screen.dart';
import 'package:mediqux_mobile/screens/institutions/institutions_list_screen.dart';
import 'package:mediqux_mobile/screens/lab_reports/lab_report_detail_screen.dart';
import 'package:mediqux_mobile/screens/lab_reports/lab_report_form_screen.dart';
import 'package:mediqux_mobile/screens/lab_reports/lab_reports_list_screen.dart';
import 'package:mediqux_mobile/screens/medications/medication_detail_screen.dart';
import 'package:mediqux_mobile/screens/medications/medication_form_screen.dart';
import 'package:mediqux_mobile/screens/medications/medications_list_screen.dart';
import 'package:mediqux_mobile/screens/patients/patient_detail_screen.dart';
import 'package:mediqux_mobile/screens/patients/patient_form_screen.dart';
import 'package:mediqux_mobile/screens/patients/patients_list_screen.dart';
import 'package:mediqux_mobile/screens/prescriptions/prescription_detail_screen.dart';
import 'package:mediqux_mobile/screens/prescriptions/prescription_form_screen.dart';
import 'package:mediqux_mobile/screens/prescriptions/prescriptions_list_screen.dart';
import 'package:mediqux_mobile/screens/setup/server_setup_screen.dart';

GoRoute _crudRoute({
  required String path,
  required Widget Function() list,
  required Widget Function() newForm,
  required Widget Function(String id) detail,
  required Widget Function(String id) editForm,
}) {
  return GoRoute(
    path: path,
    builder: (_, __) => list(),
    routes: [
      GoRoute(path: 'new', builder: (_, __) => newForm()),
      GoRoute(
        path: ':id',
        builder: (_, state) => detail(state.pathParameters['id'] ?? ''),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => editForm(state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/setup', builder: (_, __) => const ServerSetupScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
      _crudRoute(
        path: '/patients',
        list: () => const PatientsListScreen(),
        newForm: () => const PatientFormScreen(),
        detail: (id) => PatientDetailScreen(patientId: id),
        editForm: (id) => PatientFormScreen(patientId: id),
      ),
      _crudRoute(
        path: '/doctors',
        list: () => const DoctorsListScreen(),
        newForm: () => const DoctorFormScreen(),
        detail: (id) => DoctorDetailScreen(doctorId: id),
        editForm: (id) => DoctorFormScreen(doctorId: id),
      ),
      _crudRoute(
        path: '/institutions',
        list: () => const InstitutionsListScreen(),
        newForm: () => const InstitutionFormScreen(),
        detail: (id) => InstitutionDetailScreen(institutionId: id),
        editForm: (id) => InstitutionFormScreen(institutionId: id),
      ),
      _crudRoute(
        path: '/appointments',
        list: () => const AppointmentsListScreen(),
        newForm: () => const AppointmentFormScreen(),
        detail: (id) => AppointmentDetailScreen(appointmentId: id),
        editForm: (id) => AppointmentFormScreen(appointmentId: id),
      ),
      _crudRoute(
        path: '/conditions',
        list: () => const ConditionsListScreen(),
        newForm: () => const ConditionFormScreen(),
        detail: (id) => ConditionDetailScreen(conditionId: id),
        editForm: (id) => ConditionFormScreen(conditionId: id),
      ),
      _crudRoute(
        path: '/medications',
        list: () => const MedicationsListScreen(),
        newForm: () => const MedicationFormScreen(),
        detail: (id) => MedicationDetailScreen(medicationId: id),
        editForm: (id) => MedicationFormScreen(medicationId: id),
      ),
      _crudRoute(
        path: '/prescriptions',
        list: () => const PrescriptionsListScreen(),
        newForm: () => const PrescriptionFormScreen(),
        detail: (id) => PrescriptionDetailScreen(prescriptionId: id),
        editForm: (id) => PrescriptionFormScreen(prescriptionId: id),
      ),
      GoRoute(
        path: '/lab-reports',
        builder: (_, __) => const LabReportsListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, __) => const LabReportFormScreen()),
          GoRoute(
            path: ':id',
            builder: (_, state) => LabReportDetailScreen(
              reportId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      ),
      _crudRoute(
        path: '/diagnostic-studies',
        list: () => const DiagnosticStudiesListScreen(),
        newForm: () => const DiagnosticStudyFormScreen(),
        detail: (id) => DiagnosticStudyDetailScreen(studyId: id),
        editForm: (id) => DiagnosticStudyFormScreen(studyId: id),
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    _serverState = ref.read(serverConfigProvider);
    _authState = ref.read(authProvider);

    ref
      ..listen<AsyncValue<String?>>(serverConfigProvider, (_, next) {
        _serverState = next;
        notifyListeners();
      })
      ..listen<AsyncValue<User?>>(authProvider, (_, next) {
        _authState = next;
        notifyListeners();
      });
  }

  late AsyncValue<String?> _serverState;
  late AsyncValue<User?> _authState;

  String? redirect(BuildContext context, GoRouterState state) {
    if (_serverState.isLoading || _authState.isLoading) {
      return null;
    }

    final loc = state.matchedLocation;
    final hasServer = _serverState.valueOrNull != null;
    final isLoggedIn = _authState.valueOrNull != null;

    if (!hasServer && loc != '/setup') return '/setup';
    if (hasServer && !isLoggedIn && loc != '/login') {
      return '/login';
    }
    if (hasServer && isLoggedIn && loc == '/login') {
      return '/';
    }
    return null;
  }
}
