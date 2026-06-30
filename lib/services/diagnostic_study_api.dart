import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study_list_response.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study_response.dart';
import 'package:retrofit/retrofit.dart';

part 'diagnostic_study_api.g.dart';

@RestApi()
abstract class DiagnosticStudyApi {
  factory DiagnosticStudyApi(Dio dio, {String baseUrl}) = _DiagnosticStudyApi;

  @GET('/diagnostic-studies')
  Future<DiagnosticStudyListResponse> getStudies();

  @GET('/diagnostic-studies/{id}')
  Future<DiagnosticStudyResponse> getStudy(@Path('id') String id);

  @DELETE('/diagnostic-studies/{id}')
  Future<void> deleteStudy(@Path('id') String id);
}
