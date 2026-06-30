import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'diagnostic_study.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StudyPhysician extends Equatable {
  const StudyPhysician({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.specialty,
  });

  factory StudyPhysician.fromJson(Map<String, dynamic> json) =>
      _$StudyPhysicianFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final String? specialty;

  String get fullName => 'Dr. $firstName $lastName';

  Map<String, dynamic> toJson() => _$StudyPhysicianToJson(this);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class StudyInstitution extends Equatable {
  const StudyInstitution({required this.id, required this.name});

  factory StudyInstitution.fromJson(Map<String, dynamic> json) =>
      _$StudyInstitutionFromJson(json);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => _$StudyInstitutionToJson(this);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DiagnosticStudy extends Equatable {
  const DiagnosticStudy({
    required this.id,
    required this.studyType,
    required this.studyDate,
    this.bodyRegion,
    this.clinicalIndication,
    this.findings,
    this.conclusion,
    this.attachmentPath,
    this.attachmentOriginalName,
    this.attachmentMimeType,
    this.notes,
    this.createdAt,
    this.patientId,
    this.patientFirstName,
    this.patientLastName,
    this.orderingPhysician,
    this.performingPhysician,
    this.institution,
  });

  factory DiagnosticStudy.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticStudyFromJson(json);

  final String id;
  final String studyType;
  final DateTime studyDate;
  final String? bodyRegion;
  final String? clinicalIndication;
  final String? findings;
  final String? conclusion;
  final String? attachmentPath;
  final String? attachmentOriginalName;
  final String? attachmentMimeType;
  final String? notes;
  final DateTime? createdAt;
  final String? patientId;
  final String? patientFirstName;
  final String? patientLastName;
  final StudyPhysician? orderingPhysician;
  final StudyPhysician? performingPhysician;
  final StudyInstitution? institution;

  String get patientName {
    final name = '${patientFirstName ?? ''} ${patientLastName ?? ''}'.trim();
    return name.isEmpty ? 'Unknown Patient' : name;
  }

  bool get hasAttachment => attachmentPath != null;

  Map<String, dynamic> toJson() => _$DiagnosticStudyToJson(this);

  @override
  List<Object?> get props => [id];
}
