import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';

part 'patient_list_response.g.dart';

@JsonSerializable()
class PatientListResponse {
  const PatientListResponse({
    required this.success,
    this.data,
    this.error,
    this.count,
  });

  factory PatientListResponse.fromJson(Map<String, dynamic> json) =>
      _$PatientListResponseFromJson(json);

  final bool success;
  final List<Patient>? data;
  final String? error;
  final int? count;

  Map<String, dynamic> toJson() => _$PatientListResponseToJson(this);
}
