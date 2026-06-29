import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/condition/condition.dart';

part 'condition_list_response.g.dart';

@JsonSerializable()
class ConditionListResponse {
  const ConditionListResponse({
    required this.success,
    this.data,
    this.error,
    this.count,
  });

  factory ConditionListResponse.fromJson(Map<String, dynamic> json) =>
      _$ConditionListResponseFromJson(json);

  final bool success;
  final List<Condition>? data;
  final String? error;
  final int? count;
}
