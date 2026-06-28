import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/user.dart';

part 'login_response.g.dart';

// The `data` field from the API envelope: { user, token }
@JsonSerializable()
class LoginData {
  const LoginData({required this.user, required this.token});

  factory LoginData.fromJson(Map<String, dynamic> json) =>
      _$LoginDataFromJson(json);

  final User user;
  final String token;
}

// Matches the full API envelope: { success: bool, data: {...}, error: "..." }
@JsonSerializable()
class LoginResponse {
  const LoginResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  final bool success;
  final LoginData? data;
  final String? error;
}
