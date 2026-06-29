import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/condition/condition.dart';

part 'condition_response.g.dart';

@JsonSerializable()
class ConditionResponse {
  const ConditionResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory ConditionResponse.fromJson(Map<String, dynamic> json) =>
      _$ConditionResponseFromJson(json);

  final bool success;
  final Condition? data;
  final String? error;
  final String? message;
}
