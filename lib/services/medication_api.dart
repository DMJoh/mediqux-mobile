import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/medication/medication_list_response.dart';
import 'package:mediqux_mobile/models/medication/medication_request.dart';
import 'package:mediqux_mobile/models/medication/medication_response.dart';
import 'package:retrofit/retrofit.dart';

part 'medication_api.g.dart';

@RestApi()
abstract class MedicationApi {
  factory MedicationApi(Dio dio, {String baseUrl}) = _MedicationApi;

  @GET('/medications')
  Future<MedicationListResponse> getMedications();

  @GET('/medications/{id}')
  Future<MedicationResponse> getMedication(@Path('id') String id);

  @POST('/medications')
  Future<MedicationResponse> createMedication(
    @Body() MedicationRequest request,
  );

  @PUT('/medications/{id}')
  Future<MedicationResponse> updateMedication(
    @Path('id') String id,
    @Body() MedicationRequest request,
  );

  @DELETE('/medications/{id}')
  Future<void> deleteMedication(@Path('id') String id);
}
