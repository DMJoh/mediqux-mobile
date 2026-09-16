import 'package:json_annotation/json_annotation.dart';

part 'refresh_response.g.dart';

@JsonSerializable()
class RefreshData {
  const RefreshData({required this.token});

  factory RefreshData.fromJson(Map<String, dynamic> json) =>
      _$RefreshDataFromJson(json);

  final String token;
}

@JsonSerializable()
class RefreshResponse {
  const RefreshResponse({required this.success, this.data, this.error});

  factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseFromJson(json);

  final bool success;
  final RefreshData? data;
  final String? error;
}
