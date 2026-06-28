import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'appointment_stats.g.dart';

// PostgreSQL COUNT() returns bigint, which the pg Node.js driver serialises
// as a string. This converter handles both int and string safely.
int _parseCount(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class AppointmentStats extends Equatable {
  const AppointmentStats({
    required this.totalAppointments,
    required this.upcoming,
    required this.completed,
    required this.cancelled,
    required this.today,
  });

  factory AppointmentStats.fromJson(Map<String, dynamic> json) =>
      _$AppointmentStatsFromJson(json);

  @JsonKey(name: 'total_appointments', fromJson: _parseCount)
  final int totalAppointments;

  @JsonKey(fromJson: _parseCount)
  final int upcoming;

  @JsonKey(fromJson: _parseCount)
  final int completed;

  @JsonKey(fromJson: _parseCount)
  final int cancelled;

  @JsonKey(fromJson: _parseCount)
  final int today;

  @override
  List<Object?> get props => [
    totalAppointments,
    upcoming,
    completed,
    cancelled,
    today,
  ];
}

@JsonSerializable()
class AppointmentStatsResponse {
  const AppointmentStatsResponse({required this.success, required this.data});

  factory AppointmentStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$AppointmentStatsResponseFromJson(json);

  final bool success;
  final AppointmentStats data;
}

@JsonSerializable()
class PatientsCountResponse {
  const PatientsCountResponse({required this.success, required this.count});

  factory PatientsCountResponse.fromJson(Map<String, dynamic> json) =>
      _$PatientsCountResponseFromJson(json);

  final bool success;
  final int count;
}
