import 'package:json_annotation/json_annotation.dart';

part 'condition_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ConditionRequest {
  const ConditionRequest({
    required this.name,
    this.description,
    this.icdCode,
    this.category,
    this.severity,
  });

  factory ConditionRequest.fromJson(Map<String, dynamic> json) =>
      _$ConditionRequestFromJson(json);

  final String name;
  final String? description;
  final String? icdCode;
  final String? category;
  final String? severity;

  Map<String, dynamic> toJson() => _$ConditionRequestToJson(this);
}
