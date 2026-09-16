import 'package:dio/dio.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/providers/storage_provider.dart';
import 'package:mediqux_mobile/services/auth_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'refresh_coordinator_provider.g.dart';

/// Coordinates `/auth/refresh` calls so the proactive refresh timer
/// ([lib/providers/auth_provider.dart]) and the reactive 401/403 Dio
/// interceptor ([lib/providers/dio_provider.dart]) never race each other —
/// whichever caller arrives second awaits the first's in-flight result
/// instead of firing a second request.
@Riverpod(keepAlive: true)
class RefreshCoordinator extends _$RefreshCoordinator {
  Future<String?>? _inFlight;

  @override
  void build() {}

  Future<String?> refresh() =>
      _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);

  Future<String?> _doRefresh() async {
    final storage = ref.read(storageServiceProvider);
    final serverUrl = ref.read(serverConfigProvider).value ?? '';
    final oldToken = await storage.readToken();
    if (oldToken == null) return null;
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: serverUrl))
        ..options.headers['Authorization'] = 'Bearer $oldToken';
      final response = await AuthApi(refreshDio).refresh();
      if (response.success && response.data != null) {
        await storage.saveToken(response.data!.token);
        return response.data!.token;
      }
    } on Object {
      // Refresh failed — caller falls back to logout.
    }
    return null;
  }
}
