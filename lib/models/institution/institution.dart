import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'institution.g.dart';

int _parseCount(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Institution extends Equatable {
  const Institution({
    required this.id,
    required this.name,
    this.type,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.doctorCount = 0,
    this.doctors,
    this.createdAt,
    this.updatedAt,
  });

  factory Institution.fromJson(Map<String, dynamic> json) =>
      _$InstitutionFromJson(json);

  final String id;
  final String name;
  final String? type;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  @JsonKey(fromJson: _parseCount)
  final int doctorCount;
  final List<InstitutionDoctor>? doctors;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$InstitutionToJson(this);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class InstitutionDoctor extends Equatable {
  const InstitutionDoctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.specialty,
  });

  factory InstitutionDoctor.fromJson(Map<String, dynamic> json) =>
      _$InstitutionDoctorFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final String? specialty;

  String get fullName => 'Dr. $firstName $lastName';

  Map<String, dynamic> toJson() => _$InstitutionDoctorToJson(this);

  @override
  List<Object?> get props => [id];
}
