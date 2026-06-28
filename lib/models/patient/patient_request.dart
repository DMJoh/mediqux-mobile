import 'package:json_annotation/json_annotation.dart';

part 'patient_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PatientRequest {
  const PatientRequest({
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.email,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory PatientRequest.fromJson(Map<String, dynamic> json) =>
      _$PatientRequestFromJson(json);

  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? email;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  Map<String, dynamic> toJson() => _$PatientRequestToJson(this);
}
