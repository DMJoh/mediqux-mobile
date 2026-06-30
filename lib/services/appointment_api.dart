import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/appointment/appointment_list_response.dart';
import 'package:mediqux_mobile/models/appointment/appointment_request.dart';
import 'package:mediqux_mobile/models/appointment/appointment_response.dart';
import 'package:retrofit/retrofit.dart';

part 'appointment_api.g.dart';

@RestApi()
abstract class AppointmentApi {
  factory AppointmentApi(Dio dio, {String baseUrl}) = _AppointmentApi;

  @GET('/appointments')
  Future<AppointmentListResponse> getAppointments();

  @GET('/appointments/{id}')
  Future<AppointmentResponse> getAppointment(@Path('id') String id);

  @POST('/appointments')
  Future<AppointmentResponse> createAppointment(
    @Body() AppointmentRequest request,
  );

  @PUT('/appointments/{id}')
  Future<AppointmentResponse> updateAppointment(
    @Path('id') String id,
    @Body() AppointmentRequest request,
  );

  @DELETE('/appointments/{id}')
  Future<void> deleteAppointment(@Path('id') String id);
}
