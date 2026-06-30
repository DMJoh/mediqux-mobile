import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';

part 'doctor_list_response.g.dart';

@JsonSerializable()
class DoctorListResponse {
  const DoctorListResponse({
    required this.success,
    required this.count,
    this.data,
    this.error,
  });

  factory DoctorListResponse.fromJson(Map<String, dynamic> json) =>
      _$DoctorListResponseFromJson(json);

  final bool success;
  final List<Doctor>? data;
  final String? error;
  @JsonKey(fromJson: _parseCount)
  final int count;
}

int _parseCount(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
