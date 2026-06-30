import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lab_report.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class LabValue extends Equatable {
  const LabValue({
    required this.id,
    required this.parameterName,
    required this.value,
    required this.status,
    this.unit,
    this.referenceRange,
  });

  factory LabValue.fromJson(Map<String, dynamic> json) =>
      _$LabValueFromJson(json);

  final String id;
  final String parameterName;
  @JsonKey(fromJson: _toDouble)
  final double value;
  final String? unit;
  final String? referenceRange;
  final String status;

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.parse(v.toString());
  }

  Map<String, dynamic> toJson() => _$LabValueToJson(this);

  @override
  List<Object?> get props => [id];
}

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
    this.labValues,
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
  final List<LabValue>? labValues;

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
