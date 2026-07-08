import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/auth/login_request.dart';
import 'package:mediqux_mobile/models/user.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/providers/condition_provider.dart';
import 'package:mediqux_mobile/providers/diagnostic_study_provider.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/doctor_provider.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';
import 'package:mediqux_mobile/providers/lab_report_provider.dart';
import 'package:mediqux_mobile/providers/medication_provider.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';
import 'package:mediqux_mobile/providers/prescription_provider.dart';
import 'package:mediqux_mobile/providers/session_provider.dart';
import 'package:mediqux_mobile/providers/storage_provider.dart';
import 'package:mediqux_mobile/services/auth_api.dart';
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
      state = AsyncValue.error(_extractError(e), st);
    } on Object catch (_, st) {
      state = AsyncValue.error('An unexpected error occurred', st);
    }
  }

  Future<void> logout() async {
    await ref.read(storageServiceProvider).clearAuth();
    _invalidateDataCache();
    state = const AsyncValue.data(null);
  }

  void _invalidateDataCache() {
    ref
      ..invalidate(appointmentsProvider)
      ..invalidate(conditionsProvider)
      ..invalidate(diagnosticStudiesProvider)
      ..invalidate(doctorsProvider)
      ..invalidate(institutionsProvider)
      ..invalidate(labReportsProvider)
      ..invalidate(medicationsProvider)
      ..invalidate(patientsProvider)
      ..invalidate(prescriptionsProvider);
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'];
      if (message is String && message.isNotEmpty) return message;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your connection.';
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return 'Network error. Please try again.';
    }
  }
}
