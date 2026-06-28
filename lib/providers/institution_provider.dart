import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/models/institution/institution_request.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/services/institution_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'institution_provider.g.dart';

@Riverpod(keepAlive: true)
class Institutions extends _$Institutions {
  @override
  Future<List<Institution>> build() async {
    final api = InstitutionApi(ref.watch(dioProvider));
    final response = await api.getInstitutions();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
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
      final current = state.valueOrNull ?? [];
      final updated = [...current, institution]
        ..sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(updated);
      return institution;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Institution> saveInstitution(
    String id,
    InstitutionRequest request,
  ) async {
    final api = InstitutionApi(ref.read(dioProvider));
    try {
      final response =
          await api.updateInstitution(id, request);
      final updated = response.data!;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current
            .map((i) => i.id == id ? updated : i)
            .toList(),
      );
      return updated;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> delete(String id) async {
    final api = InstitutionApi(ref.read(dioProvider));
    try {
      await api.deleteInstitution(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.where((i) => i.id != id).toList(),
      );
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
Future<Institution> institutionDetail(
  Ref ref,
  String institutionId,
) async {
  final api = InstitutionApi(ref.watch(dioProvider));
  final response = await api.getInstitution(institutionId);
  return response.data!;
}
