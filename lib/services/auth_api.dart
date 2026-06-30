import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/auth/login_request.dart';
import 'package:mediqux_mobile/models/auth/login_response.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

@RestApi()
// Retrofit codegen requires an abstract class.
// ignore: one_member_abstracts
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/auth/login')
  Future<LoginResponse> login(@Body() LoginRequest body);
}
