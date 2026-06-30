import 'package:json_annotation/json_annotation.dart';

part 'doctor_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DoctorRequest {
  const DoctorRequest({
    required this.firstName,
    required this.lastName,
    this.specialty,
    this.licenseNumber,
    this.phone,
    this.email,
    this.institutionIds,
  });

  factory DoctorRequest.fromJson(Map<String, dynamic> json) =>
      _$DoctorRequestFromJson(json);

  final String firstName;
  final String lastName;
  final String? specialty;
  final String? licenseNumber;
  final String? phone;
  final String? email;
  final List<String>? institutionIds;

  Map<String, dynamic> toJson() => _$DoctorRequestToJson(this);
}
