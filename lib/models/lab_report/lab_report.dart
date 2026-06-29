import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lab_report.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class LabReportPhysician extends Equatable {
  const LabReportPhysician({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.specialty,
  });

  factory LabReportPhysician.fromJson(Map<String, dynamic> json) =>
      _$LabReportPhysicianFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final String? specialty;

  String get fullName => 'Dr. $firstName $lastName';

  Map<String, dynamic> toJson() => _$LabReportPhysicianToJson(this);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LabReport extends Equatable {
  const LabReport({
    required this.id,
    required this.testName,
    required this.testDate,
    this.testType,
    this.notes,
    this.pdfFilePath,
    this.createdAt,
    this.patientId,
    this.patientFirstName,
    this.patientLastName,
    this.appointmentId,
    this.performedBy,
    this.institutionName,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) =>
      _$LabReportFromJson(json);

  final String id;
  final String testName;
  final DateTime testDate;
  final String? testType;
  final String? notes;
  final String? pdfFilePath;
  final DateTime? createdAt;
  final String? patientId;
  final String? patientFirstName;
  final String? patientLastName;
  final String? appointmentId;
  final LabReportPhysician? performedBy;
  final String? institutionName;

  String get patientName {
    final name = '${patientFirstName ?? ''} ${patientLastName ?? ''}'.trim();
    return name.isEmpty ? 'Unknown Patient' : name;
  }

  String get doctorName {
    if (performedBy == null) return '';
    return performedBy!.fullName;
  }

  bool get hasFile => pdfFilePath != null;

  Map<String, dynamic> toJson() => _$LabReportToJson(this);

  @override
  List<Object?> get props => [id];
}
