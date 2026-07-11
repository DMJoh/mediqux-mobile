import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upcoming_appointment.g.dart';

@JsonSerializable()
class UpcomingAppointment extends Equatable {
  const UpcomingAppointment({
    required this.id,
    required this.appointmentDate,
    this.type,
    this.status,
    this.patientFirstName,
    this.patientLastName,
    this.doctorFirstName,
    this.doctorLastName,
  });

  factory UpcomingAppointment.fromJson(Map<String, dynamic> json) =>
      _$UpcomingAppointmentFromJson(json);

  final String id;

  @JsonKey(name: 'appointment_date')
  final DateTime appointmentDate;

  final String? type;
  final String? status;

  @JsonKey(name: 'patient_first_name')
  final String? patientFirstName;

  @JsonKey(name: 'patient_last_name')
  final String? patientLastName;

  @JsonKey(name: 'doctor_first_name')
  final String? doctorFirstName;

  @JsonKey(name: 'doctor_last_name')
  final String? doctorLastName;

  String get patientName =>
      '${patientFirstName ?? ''} ${patientLastName ?? ''}'.trim();

  String get doctorName =>
      '${doctorFirstName ?? ''} ${doctorLastName ?? ''}'.trim();

  @override
  List<Object?> get props => [id];
}

@JsonSerializable()
class UpcomingAppointmentsResponse {
  const UpcomingAppointmentsResponse({
    required this.success,
    required this.data,
  });

  factory UpcomingAppointmentsResponse.fromJson(Map<String, dynamic> json) =>
      _$UpcomingAppointmentsResponseFromJson(json);

  final bool success;
  final List<UpcomingAppointment> data;
}
