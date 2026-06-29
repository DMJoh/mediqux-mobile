import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';

part 'appointment_list_response.g.dart';

int _parseCount(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

@JsonSerializable()
class AppointmentListResponse {
  const AppointmentListResponse({
    required this.success,
    required this.count,
    this.data,
    this.error,
  });

  factory AppointmentListResponse.fromJson(Map<String, dynamic> json) =>
      _$AppointmentListResponseFromJson(json);

  final bool success;
  final List<Appointment>? data;
  final String? error;
  @JsonKey(fromJson: _parseCount)
  final int count;
}
