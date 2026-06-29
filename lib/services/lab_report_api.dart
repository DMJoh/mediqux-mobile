import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report_list_response.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report_response.dart';
import 'package:retrofit/retrofit.dart';

part 'lab_report_api.g.dart';

@RestApi()
abstract class LabReportApi {
  factory LabReportApi(Dio dio, {String baseUrl}) = _LabReportApi;

  @GET('/test-results')
  Future<LabReportListResponse> getLabReports();

  @GET('/test-results/{id}')
  Future<LabReportResponse> getLabReport(@Path('id') String id);

  @DELETE('/test-results/{id}')
  Future<void> deleteLabReport(@Path('id') String id);
}
