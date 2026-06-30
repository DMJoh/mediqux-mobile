import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';

part 'doctor_response.g.dart';

@JsonSerializable()
class DoctorResponse {
  const DoctorResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory DoctorResponse.fromJson(Map<String, dynamic> json) =>
      _$DoctorResponseFromJson(json);

  final bool success;
  final Doctor? data;
  final String? error;
  final String? message;
}
