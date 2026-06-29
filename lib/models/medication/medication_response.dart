import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/medication/medication.dart';

part 'medication_response.g.dart';

@JsonSerializable()
class MedicationResponse {
  const MedicationResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory MedicationResponse.fromJson(Map<String, dynamic> json) =>
      _$MedicationResponseFromJson(json);

  final bool success;
  final Medication? data;
  final String? error;
  final String? message;
}
