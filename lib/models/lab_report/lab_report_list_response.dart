import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report.dart';

part 'lab_report_list_response.g.dart';

int _parseCount(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

@JsonSerializable()
class LabReportListResponse {
  const LabReportListResponse({
    required this.success,
    required this.count,
    this.data,
    this.error,
  });

  factory LabReportListResponse.fromJson(Map<String, dynamic> json) =>
      _$LabReportListResponseFromJson(json);

  final bool success;
  final List<LabReport>? data;
  final String? error;
  @JsonKey(fromJson: _parseCount)
  final int count;
}
