import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/medication/medication.dart';
import 'package:mediqux_mobile/models/medication/medication_request.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/services/medication_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medication_provider.g.dart';

@Riverpod(keepAlive: true)
class Medications extends _$Medications {
  @override
  Future<List<Medication>> build() async {
    if (ref.watch(authProvider).valueOrNull == null) return [];
    await ref.watch(serverConfigProvider.future);
    final api = MedicationApi(ref.read(dioProvider));
    final response = await api.getMedications();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final api = MedicationApi(ref.read(dioProvider));
      final response = await api.getMedications();
      return response.data ?? [];
    });
  }

  Future<Medication> create(MedicationRequest request) async {
    final api = MedicationApi(ref.read(dioProvider));
    try {
      final response = await api.createMedication(request);
      final medication = response.data!;
      final current = state.valueOrNull ?? [];
      final updated = [...current, medication]
        ..sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(updated);
      return medication;
    } on DioException {
      rethrow;
    }
  }

  Future<Medication> saveMedication(
    String id,
    MedicationRequest request,
  ) async {
    final api = MedicationApi(ref.read(dioProvider));
    try {
      final response = await api.updateMedication(id, request);
      final updated = response.data!;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((m) => m.id == id ? updated : m).toList(),
      );
      return updated;
    } on DioException {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final api = MedicationApi(ref.read(dioProvider));
    try {
      await api.deleteMedication(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((m) => m.id != id).toList());
    } on DioException {
      rethrow;
    }
  }
}

@riverpod
Future<Medication> medicationDetail(Ref ref, String medicationId) async {
  final api = MedicationApi(ref.watch(dioProvider));
  final response = await api.getMedication(medicationId);
  return response.data!;
}
