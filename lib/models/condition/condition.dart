import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'condition.g.dart';

int _parseCount(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Condition extends Equatable {
  const Condition({
    required this.id,
    required this.name,
    this.usageCount = 0,
    this.description,
    this.icdCode,
    this.category,
    this.severity,
    this.createdAt,
  });

  factory Condition.fromJson(Map<String, dynamic> json) =>
      _$ConditionFromJson(json);

  final String id;
  final String name;
  final String? description;
  final String? icdCode;
  final String? category;
  final String? severity;
  final DateTime? createdAt;
  @JsonKey(fromJson: _parseCount)
  final int usageCount;

  Map<String, dynamic> toJson() => _$ConditionToJson(this);

  @override
  List<Object?> get props => [id];
}
