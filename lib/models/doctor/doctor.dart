import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'doctor.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DoctorInstitution extends Equatable {
  const DoctorInstitution({required this.id, required this.name, this.type});

  factory DoctorInstitution.fromJson(Map<String, dynamic> json) =>
      _$DoctorInstitutionFromJson(json);

  final String id;
  final String name;
  final String? type;

  Map<String, dynamic> toJson() => _$DoctorInstitutionToJson(this);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Doctor extends Equatable {
  const Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.specialty,
    this.licenseNumber,
    this.phone,
    this.email,
    this.createdAt,
    this.institutions,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => _$DoctorFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final String? specialty;
  final String? licenseNumber;
  final String? phone;
  final String? email;
  final DateTime? createdAt;
  final List<DoctorInstitution>? institutions;

  String get fullName => 'Dr. $firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  Map<String, dynamic> toJson() => _$DoctorToJson(this);

  @override
  List<Object?> get props => [id];
}
