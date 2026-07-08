import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/prescription/prescription.dart';
import 'package:mediqux_mobile/models/prescription/prescription_request.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/services/prescription_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prescription_provider.g.dart';

@Riverpod(keepAlive: true)
class Prescriptions extends _$Prescriptions {
  @override
  Future<List<Prescription>> build() async {
    final api = PrescriptionApi(ref.watch(dioProvider));
    final response = await api.getPrescriptions();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final api = PrescriptionApi(ref.read(dioProvider));
      final response = await api.getPrescriptions();
      return response.data ?? [];
    });
  }

  Future<Prescription> create(PrescriptionRequest request) async {
    final api = PrescriptionApi(ref.read(dioProvider));
    try {
      final response = await api.createPrescription(request);
      final rx = response.data!;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([rx, ...current]);
      return rx;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Prescription> savePrescription(
    String id,
    PrescriptionRequest request,
  ) async {
    final api = PrescriptionApi(ref.read(dioProvider));
    try {
      final response = await api.updatePrescription(id, request);
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
    final api = PrescriptionApi(ref.read(dioProvider));
    try {
      await api.deletePrescription(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((p) => p.id != id).toList());
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
Future<Prescription> prescriptionDetail(Ref ref, String prescriptionId) async {
  final api = PrescriptionApi(ref.watch(dioProvider));
  final response = await api.getPrescription(prescriptionId);
  return response.data!;
}
