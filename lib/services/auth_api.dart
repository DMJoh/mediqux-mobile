import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/auth/login_request.dart';
import 'package:mediqux_mobile/models/auth/login_response.dart';
import 'package:mediqux_mobile/models/auth/refresh_response.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/auth/login')
  Future<LoginResponse> login(@Body() LoginRequest body);

  @POST('/auth/refresh')
  Future<RefreshResponse> refresh();
}
