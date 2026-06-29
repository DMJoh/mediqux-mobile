import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/prescription/prescription_list_response.dart';
import 'package:mediqux_mobile/models/prescription/prescription_request.dart';
import 'package:mediqux_mobile/models/prescription/prescription_response.dart';
import 'package:retrofit/retrofit.dart';

part 'prescription_api.g.dart';

@RestApi()
abstract class PrescriptionApi {
  factory PrescriptionApi(Dio dio, {String baseUrl}) = _PrescriptionApi;

  @GET('/prescriptions')
  Future<PrescriptionListResponse> getPrescriptions();

  @GET('/prescriptions/{id}')
  Future<PrescriptionResponse> getPrescription(@Path('id') String id);

  @POST('/prescriptions')
  Future<PrescriptionResponse> createPrescription(
    @Body() PrescriptionRequest request,
  );

  @PUT('/prescriptions/{id}')
  Future<PrescriptionResponse> updatePrescription(
    @Path('id') String id,
    @Body() PrescriptionRequest request,
  );

  @DELETE('/prescriptions/{id}')
  Future<void> deletePrescription(@Path('id') String id);
}
