import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/models/patient/patient_request.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/services/patient_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patient_provider.g.dart';

@Riverpod(keepAlive: true)
class Patients extends _$Patients {
  @override
  Future<List<Patient>> build() async {
    final api = PatientApi(ref.watch(dioProvider));
    final response = await api.getPatients();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final api = PatientApi(ref.read(dioProvider));
      final response = await api.getPatients();
      return response.data ?? [];
    });
  }

  Future<Patient> create(PatientRequest request) async {
    final api = PatientApi(ref.read(dioProvider));
    try {
      final response = await api.createPatient(request);
      final patient = response.data!;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, patient]);
      return patient;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Patient> savePatient(String id, PatientRequest request) async {
    final api = PatientApi(ref.read(dioProvider));
    try {
      final response = await api.updatePatient(id, request);
      final updated = response.data!;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((p) => p.id == id ? updated : p).toList(),
      );
      return updated;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> delete(String id) async {
    final api = PatientApi(ref.read(dioProvider));
    try {
      await api.deletePatient(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((p) => p.id != id).toList());
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
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

@riverpod
Future<Patient> patientDetail(Ref ref, String patientId) async {
  final api = PatientApi(ref.watch(dioProvider));
  final response = await api.getPatient(patientId);
  return response.data!;
}
