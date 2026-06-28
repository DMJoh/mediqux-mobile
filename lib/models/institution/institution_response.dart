import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';

part 'institution_response.g.dart';

@JsonSerializable()
class InstitutionResponse {
  const InstitutionResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory InstitutionResponse.fromJson(Map<String, dynamic> json) =>
      _$InstitutionResponseFromJson(json);

  final bool success;
  final Institution? data;
  final String? error;
  final String? message;
}
