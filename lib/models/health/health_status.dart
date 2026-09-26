import 'package:json_annotation/json_annotation.dart';

part 'health_status.g.dart';

/// The backend's `GET /health` response — unauthenticated, so this is safe
/// to call before login too (e.g. to show a server version during setup).
@JsonSerializable()
class HealthStatus {
  const HealthStatus({
    required this.status,
    required this.version,
    this.environment,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) =>
      _$HealthStatusFromJson(json);

  final String status;
  final String version;
  final String? environment;
}
