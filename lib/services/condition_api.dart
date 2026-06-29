import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/condition/condition_list_response.dart';
import 'package:mediqux_mobile/models/condition/condition_request.dart';
import 'package:mediqux_mobile/models/condition/condition_response.dart';
import 'package:retrofit/retrofit.dart';

part 'condition_api.g.dart';

@RestApi()
abstract class ConditionApi {
  factory ConditionApi(Dio dio, {String baseUrl}) = _ConditionApi;

  @GET('/conditions')
  Future<ConditionListResponse> getConditions();

  @GET('/conditions/{id}')
  Future<ConditionResponse> getCondition(@Path('id') String id);

  @POST('/conditions')
  Future<ConditionResponse> createCondition(@Body() ConditionRequest request);

  @PUT('/conditions/{id}')
  Future<ConditionResponse> updateCondition(
    @Path('id') String id,
    @Body() ConditionRequest request,
  );

  @DELETE('/conditions/{id}')
  Future<void> deleteCondition(@Path('id') String id);
}
