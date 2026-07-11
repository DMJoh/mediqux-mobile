import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/auth/login_request.dart';
import 'package:mediqux_mobile/models/user.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/session_provider.dart';
import 'package:mediqux_mobile/providers/storage_provider.dart';
import 'package:mediqux_mobile/services/auth_api.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<User?> build() async {
    ref.watch(sessionVersionProvider);
    final storage = ref.watch(storageServiceProvider);
    final token = await storage.readToken();
    if (token == null) return null;
    return storage.readUser();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    final storage = ref.read(storageServiceProvider);
    final api = AuthApi(ref.read(dioProvider));
    try {
      final response = await api.login(
        LoginRequest(username: username, password: password),
      );
      if (response.success && response.data != null) {
        await storage.saveToken(response.data!.token);
        await storage.saveUser(response.data!.user);
        state = AsyncValue.data(response.data!.user);
      } else {
        state = AsyncValue.error(
          response.error ?? 'Login failed',
          StackTrace.current,
        );
      }
    } on DioException catch (e, st) {
      state = AsyncValue.error(friendlyError(e), st);
    } on Object catch (_, st) {
      state = AsyncValue.error('An unexpected error occurred', st);
    }
  }

  Future<void> logout() async {
    await ref.read(storageServiceProvider).clearAuth();
    state = const AsyncValue.data(null);
  }
}
