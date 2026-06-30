import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/medication/medication.dart';

part 'medication_list_response.g.dart';

@JsonSerializable()
class MedicationListResponse {
  const MedicationListResponse({
    required this.success,
    this.data,
    this.error,
    this.count,
  });

  factory MedicationListResponse.fromJson(Map<String, dynamic> json) =>
      _$MedicationListResponseFromJson(json);

  final bool success;
  final List<Medication>? data;
  final String? error;
  final int? count;
}
