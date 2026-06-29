import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report.dart';

part 'lab_report_response.g.dart';

@JsonSerializable()
class LabReportResponse {
  const LabReportResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory LabReportResponse.fromJson(Map<String, dynamic> json) =>
      _$LabReportResponseFromJson(json);

  final bool success;
  final LabReport? data;
  final String? error;
  final String? message;
}
