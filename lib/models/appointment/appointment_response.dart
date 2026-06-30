import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';

part 'appointment_response.g.dart';

@JsonSerializable()
class AppointmentResponse {
  const AppointmentResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory AppointmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AppointmentResponseFromJson(json);

  final bool success;
  final Appointment? data;
  final String? error;
  final String? message;
}
