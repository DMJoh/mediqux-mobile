import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'prescription.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Prescription extends Equatable {
  const Prescription({
    required this.id,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.appointmentId,
    this.medicationId,
    this.instructions,
    this.createdAt,
    this.patientId,
    this.patientFirstName,
    this.patientLastName,
    this.medicationName,
    this.medicationGenericName,
    this.appointmentDate,
    this.doctorFirstName,
    this.doctorLastName,
    this.institutionName,
    this.status,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) =>
      _$PrescriptionFromJson(json);

  final String id;
  final String dosage;
  final String frequency;
  final String duration;
  final String? appointmentId;
  final String? medicationId;
  final String? instructions;
  final DateTime? createdAt;
  final String? patientId;
  final String? patientFirstName;
  final String? patientLastName;
  final String? medicationName;
  final String? medicationGenericName;
  final DateTime? appointmentDate;
  final String? doctorFirstName;
  final String? doctorLastName;
  final String? institutionName;
  final String? status;

  String get patientName {
    final name = '${patientFirstName ?? ''} ${patientLastName ?? ''}'.trim();
    return name.isEmpty ? 'Unknown Patient' : name;
  }

  String get doctorName {
    if (doctorFirstName == null && doctorLastName == null) return '';
    return 'Dr. ${doctorFirstName ?? ''} ${doctorLastName ?? ''}'.trim();
  }

  String get medicationDisplay => medicationName ?? 'Unknown';

  Map<String, dynamic> toJson() => _$PrescriptionToJson(this);

  @override
  List<Object?> get props => [id];
}
