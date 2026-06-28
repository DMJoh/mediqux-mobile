import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/patient/patient_list_response.dart';
import 'package:mediqux_mobile/models/patient/patient_request.dart';
import 'package:mediqux_mobile/models/patient/patient_response.dart';
import 'package:retrofit/retrofit.dart';

part 'patient_api.g.dart';

@RestApi()
abstract class PatientApi {
  factory PatientApi(Dio dio, {String baseUrl}) = _PatientApi;

  @GET('/patients')
  Future<PatientListResponse> getPatients();

  @GET('/patients/{id}')
  Future<PatientResponse> getPatient(@Path('id') String id);

  @POST('/patients')
  Future<PatientResponse> createPatient(
    @Body() PatientRequest body,
  );

  @PUT('/patients/{id}')
  Future<PatientResponse> updatePatient(
    @Path('id') String id,
    @Body() PatientRequest body,
  );

  @DELETE('/patients/{id}')
  Future<PatientResponse> deletePatient(@Path('id') String id);
}
