import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study.dart';

part 'diagnostic_study_response.g.dart';

@JsonSerializable()
class DiagnosticStudyResponse {
  const DiagnosticStudyResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory DiagnosticStudyResponse.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticStudyResponseFromJson(json);

  final bool success;
  final DiagnosticStudy? data;
  final String? error;
  final String? message;
}
