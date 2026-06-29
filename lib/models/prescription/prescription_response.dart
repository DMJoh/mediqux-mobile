import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/prescription/prescription.dart';

part 'prescription_response.g.dart';

@JsonSerializable()
class PrescriptionResponse {
  const PrescriptionResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory PrescriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$PrescriptionResponseFromJson(json);

  final bool success;
  final Prescription? data;
  final String? error;
  final String? message;
}
