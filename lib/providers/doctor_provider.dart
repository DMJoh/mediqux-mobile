import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';
import 'package:mediqux_mobile/models/doctor/doctor_request.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/services/doctor_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'doctor_provider.g.dart';

@Riverpod(keepAlive: true)
class Doctors extends _$Doctors {
  @override
  Future<List<Doctor>> build() async {
    final api = DoctorApi(ref.watch(dioProvider));
    final response = await api.getDoctors();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final api = DoctorApi(ref.read(dioProvider));
      final response = await api.getDoctors();
      return response.data ?? [];
    });
  }

  Future<Doctor> create(DoctorRequest request) async {
    final api = DoctorApi(ref.read(dioProvider));
    try {
      final response = await api.createDoctor(request);
      final doctor = response.data!;
      final current = state.valueOrNull ?? [];
      final updated = [...current, doctor]
        ..sort((a, b) => a.lastName.compareTo(b.lastName));
      state = AsyncValue.data(updated);
      return doctor;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Doctor> saveDoctor(String id, DoctorRequest request) async {
    final api = DoctorApi(ref.read(dioProvider));
    try {
      final response = await api.updateDoctor(id, request);
      final updated = response.data!;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((d) => d.id == id ? updated : d).toList(),
      );
      return updated;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> delete(String id) async {
    final api = DoctorApi(ref.read(dioProvider));
    try {
      await api.deleteDoctor(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((d) => d.id != id).toList());
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['error'];
      if (msg is String && msg.isNotEmpty) return msg;
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
Future<Doctor> doctorDetail(Ref ref, String doctorId) async {
  final api = DoctorApi(ref.watch(dioProvider));
  final response = await api.getDoctor(doctorId);
  return response.data!;
}

@riverpod
Future<List<Map<String, String>>> availableInstitutions(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Map<String, dynamic>>(
    '/doctors/institutions/available',
  );
  final data = response.data?['data'];
  if (data is! List) return [];
  return data.map((e) {
    final m = e as Map<String, dynamic>;
    return {
      'id': (m['id'] as String?) ?? '',
      'name': (m['name'] as String?) ?? '',
      'type': (m['type'] as String?) ?? '',
    };
  }).toList();
}
