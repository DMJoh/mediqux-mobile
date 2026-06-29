import 'package:json_annotation/json_annotation.dart';

part 'appointment_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class AppointmentRequest {
  const AppointmentRequest({
    required this.patientId,
    required this.appointmentDate,
    this.doctorId,
    this.institutionId,
    this.type,
    this.status = 'scheduled',
    this.notes,
    this.diagnosis,
  });

  factory AppointmentRequest.fromJson(Map<String, dynamic> json) =>
      _$AppointmentRequestFromJson(json);

  final String patientId;
  final String appointmentDate;
  final String? doctorId;
  final String? institutionId;
  final String? type;
  final String? status;
  final String? notes;
  final String? diagnosis;

  Map<String, dynamic> toJson() => _$AppointmentRequestToJson(this);
}
