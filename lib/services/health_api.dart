import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/health/health_status.dart';
import 'package:retrofit/retrofit.dart';

part 'health_api.g.dart';

@RestApi()
// Retrofit requires this shape regardless of method count, and there's
// genuinely only one endpoint to expose here.
// ignore: one_member_abstracts
abstract class HealthApi {
  factory HealthApi(Dio dio, {String baseUrl}) = _HealthApi;

  @GET('/health')
  Future<HealthStatus> getHealth();
}
