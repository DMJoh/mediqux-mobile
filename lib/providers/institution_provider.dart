import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/models/institution/institution_request.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/services/institution_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'institution_provider.g.dart';

@Riverpod(keepAlive: true)
class Institutions extends _$Institutions {
  @override
  Future<List<Institution>> build() async {
    if (ref.watch(authProvider).value == null) return [];
    await ref.watch(serverConfigProvider.future);
    final api = InstitutionApi(ref.read(dioProvider));
    final response = await api.getInstitutions();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final api = InstitutionApi(ref.read(dioProvider));
      final response = await api.getInstitutions();
      return response.data ?? [];
    });
  }

  Future<Institution> create(InstitutionRequest request) async {
    final api = InstitutionApi(ref.read(dioProvider));
    try {
      final response = await api.createInstitution(request);
      final institution = response.data!;
      final current = state.value ?? [];
      final updated = [...current, institution]
        ..sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(updated);
      return institution;
    } on DioException {
      rethrow;
    }
  }

  Future<Institution> saveInstitution(
    String id,
    InstitutionRequest request,
  ) async {
    final api = InstitutionApi(ref.read(dioProvider));
    try {
      final response = await api.updateInstitution(id, request);
      final updated = response.data!;
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((i) => i.id == id ? updated : i).toList(),
      );
      return updated;
    } on DioException {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final api = InstitutionApi(ref.read(dioProvider));
    try {
      await api.deleteInstitution(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((i) => i.id != id).toList());
    } on DioException {
      rethrow;
    }
  }
}

@riverpod
Future<Institution> institutionDetail(Ref ref, String institutionId) async {
  final api = InstitutionApi(ref.watch(dioProvider));
  final response = await api.getInstitution(institutionId);
  return response.data!;
}
