import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patient.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Patient extends Equatable {
  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.email,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.createdAt,
    this.updatedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? email;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty
        ? firstName[0].toUpperCase()
        : '';
    final l = lastName.isNotEmpty
        ? lastName[0].toUpperCase()
        : '';
    return '$f$l';
  }

  int? get age {
    if (dateOfBirth == null || dateOfBirth!.isEmpty) return null;
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return null;
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a < 0 ? 0 : a;
  }

  Map<String, dynamic> toJson() => _$PatientToJson(this);

  @override
  List<Object?> get props => [id];
}
