import 'package:mediqux_mobile/models/health/health_status.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/services/health_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_provider.g.dart';

@riverpod
Future<HealthStatus> apiHealth(Ref ref) async {
  final api = HealthApi(ref.watch(dioProvider));
  return api.getHealth();
}
