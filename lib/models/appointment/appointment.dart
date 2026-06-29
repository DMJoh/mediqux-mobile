import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.appointmentDate,
    required this.status,
    this.type,
    this.notes,
    this.diagnosis,
    this.createdAt,
    this.patientId,
    this.patientFirstName,
    this.patientLastName,
    this.patientPhone,
    this.doctorId,
    this.doctorFirstName,
    this.doctorLastName,
    this.doctorSpecialty,
    this.institutionId,
    this.institutionName,
    this.institutionType,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);

  final String id;
  final DateTime appointmentDate;
  final String status;
  final String? type;
  final String? notes;
  final String? diagnosis;
  final DateTime? createdAt;
  final String? patientId;
  final String? patientFirstName;
  final String? patientLastName;
  final String? patientPhone;
  final String? doctorId;
  final String? doctorFirstName;
  final String? doctorLastName;
  final String? doctorSpecialty;
  final String? institutionId;
  final String? institutionName;
  final String? institutionType;

  String get patientName {
    final name = '${patientFirstName ?? ''} ${patientLastName ?? ''}'.trim();
    return name.isEmpty ? 'Unknown Patient' : name;
  }

  String get doctorName {
    if (doctorFirstName == null && doctorLastName == null) return '';
    return 'Dr. ${doctorFirstName ?? ''} ${doctorLastName ?? ''}'.trim();
  }

  bool get isUpcoming => appointmentDate.isAfter(DateTime.now());

  Map<String, dynamic> toJson() => _$AppointmentToJson(this);

  @override
  List<Object?> get props => [id];
}
