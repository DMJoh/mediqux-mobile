import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/doctor/doctor_list_response.dart';
import 'package:mediqux_mobile/models/doctor/doctor_request.dart';
import 'package:mediqux_mobile/models/doctor/doctor_response.dart';
import 'package:retrofit/retrofit.dart';

part 'doctor_api.g.dart';

@RestApi()
abstract class DoctorApi {
  factory DoctorApi(Dio dio, {String baseUrl}) = _DoctorApi;

  @GET('/doctors')
  Future<DoctorListResponse> getDoctors();

  @GET('/doctors/{id}')
  Future<DoctorResponse> getDoctor(@Path('id') String id);

  @POST('/doctors')
  Future<DoctorResponse> createDoctor(@Body() DoctorRequest request);

  @PUT('/doctors/{id}')
  Future<DoctorResponse> updateDoctor(
    @Path('id') String id,
    @Body() DoctorRequest request,
  );

  @DELETE('/doctors/{id}')
  Future<void> deleteDoctor(@Path('id') String id);
}
