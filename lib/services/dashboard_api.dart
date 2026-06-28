import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/dashboard/appointment_stats.dart';
import 'package:mediqux_mobile/models/dashboard/upcoming_appointment.dart';
import 'package:retrofit/retrofit.dart';

part 'dashboard_api.g.dart';

@RestApi()
abstract class DashboardApi {
  factory DashboardApi(Dio dio, {String baseUrl}) = _DashboardApi;

  @GET('/appointments/dashboard/upcoming')
  Future<UpcomingAppointmentsResponse> getUpcomingAppointments();

  @GET('/appointments/stats/summary')
  Future<AppointmentStatsResponse> getAppointmentStats();

  @GET('/patients')
  Future<PatientsCountResponse> getPatientCount();
}
