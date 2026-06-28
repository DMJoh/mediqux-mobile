import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/institution/institution_list_response.dart';
import 'package:mediqux_mobile/models/institution/institution_request.dart';
import 'package:mediqux_mobile/models/institution/institution_response.dart';
import 'package:retrofit/retrofit.dart';

part 'institution_api.g.dart';

@RestApi()
abstract class InstitutionApi {
  factory InstitutionApi(Dio dio, {String baseUrl}) = _InstitutionApi;

  @GET('/institutions')
  Future<InstitutionListResponse> getInstitutions();

  @GET('/institutions/{id}')
  Future<InstitutionResponse> getInstitution(@Path('id') String id);

  @POST('/institutions')
  Future<InstitutionResponse> createInstitution(
    @Body() InstitutionRequest body,
  );

  @PUT('/institutions/{id}')
  Future<InstitutionResponse> updateInstitution(
    @Path('id') String id,
    @Body() InstitutionRequest body,
  );

  @DELETE('/institutions/{id}')
  Future<InstitutionResponse> deleteInstitution(@Path('id') String id);
}
