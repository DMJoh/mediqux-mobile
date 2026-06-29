import 'package:json_annotation/json_annotation.dart';

part 'medication_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MedicationRequest {
  const MedicationRequest({
    required this.name,
    this.dosageForms = const [],
    this.strengths = const [],
    this.activeIngredients = const [],
    this.genericName,
    this.manufacturer,
    this.description,
  });

  factory MedicationRequest.fromJson(Map<String, dynamic> json) =>
      _$MedicationRequestFromJson(json);

  final String name;
  final String? genericName;
  final List<String> dosageForms;
  final List<String> strengths;
  final List<dynamic> activeIngredients;
  final String? manufacturer;
  final String? description;

  Map<String, dynamic> toJson() => _$MedicationRequestToJson(this);
}
