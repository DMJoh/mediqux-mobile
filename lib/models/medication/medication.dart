import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'medication.g.dart';

int _parseCount(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Medication extends Equatable {
  const Medication({
    required this.id,
    required this.name,
    this.dosageForms = const [],
    this.strengths = const [],
    this.activeIngredients = const [],
    this.prescriptionCount = 0,
    this.patientMedicationCount = 0,
    this.genericName,
    this.manufacturer,
    this.description,
    this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) =>
      _$MedicationFromJson(json);

  final String id;
  final String name;
  final String? genericName;
  final List<String> dosageForms;
  final List<String> strengths;
  final List<dynamic> activeIngredients;
  final String? manufacturer;
  final String? description;
  @JsonKey(fromJson: _parseCount)
  final int prescriptionCount;
  @JsonKey(fromJson: _parseCount)
  final int patientMedicationCount;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => _$MedicationToJson(this);

  @override
  List<Object?> get props => [id];
}
