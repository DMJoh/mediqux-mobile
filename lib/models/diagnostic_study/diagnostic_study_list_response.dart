import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study.dart';

part 'diagnostic_study_list_response.g.dart';

int _parseCount(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

@JsonSerializable()
class DiagnosticStudyListResponse {
  const DiagnosticStudyListResponse({
    required this.success,
    required this.count,
    this.data,
    this.error,
  });

  factory DiagnosticStudyListResponse.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticStudyListResponseFromJson(json);

  final bool success;
  final List<DiagnosticStudy>? data;
  final String? error;
  @JsonKey(fromJson: _parseCount)
  final int count;
}
