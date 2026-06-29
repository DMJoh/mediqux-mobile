import 'package:json_annotation/json_annotation.dart';

part 'prescription_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class PrescriptionRequest {
  const PrescriptionRequest({
    required this.appointmentId,
    required this.medicationId,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
    this.status,
  });

  factory PrescriptionRequest.fromJson(Map<String, dynamic> json) =>
      _$PrescriptionRequestFromJson(json);

  final String appointmentId;
  final String medicationId;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;
  final String? status;

  Map<String, dynamic> toJson() => _$PrescriptionRequestToJson(this);
}
