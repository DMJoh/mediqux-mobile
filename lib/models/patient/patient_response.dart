import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';

part 'patient_response.g.dart';

@JsonSerializable()
class PatientResponse {
  const PatientResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory PatientResponse.fromJson(Map<String, dynamic> json) =>
      _$PatientResponseFromJson(json);

  final bool success;
  final Patient? data;
  final String? error;
  final String? message;

  Map<String, dynamic> toJson() => _$PatientResponseToJson(this);
}
