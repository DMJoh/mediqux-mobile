import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/dashboard/appointment_stats.dart';
import 'package:mediqux_mobile/models/dashboard/upcoming_appointment.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/services/dashboard_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<List<UpcomingAppointment>> upcomingAppointments(Ref ref) async {
  final api = DashboardApi(ref.watch(dioProvider));
  final response = await api.getUpcomingAppointments();
  return response.data;
}

@riverpod
Future<AppointmentStats> appointmentStats(Ref ref) async {
  final api = DashboardApi(ref.watch(dioProvider));
  final response = await api.getAppointmentStats();
  return response.data;
}

@riverpod
Future<int> patientCount(Ref ref) async {
  final api = DashboardApi(ref.watch(dioProvider));
  final response = await api.getPatientCount();
  return response.count;
}
