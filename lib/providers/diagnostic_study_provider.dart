import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/services/diagnostic_study_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diagnostic_study_provider.g.dart';

@Riverpod(keepAlive: true)
class DiagnosticStudies extends _$DiagnosticStudies {
  @override
  Future<List<DiagnosticStudy>> build() async {
    final api = DiagnosticStudyApi(ref.watch(dioProvider));
    final response = await api.getStudies();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = DiagnosticStudyApi(ref.read(dioProvider));
      final response = await api.getStudies();
      return response.data ?? [];
    });
  }

  Future<void> create({
    required String patientId,
    required String studyType,
    required DateTime studyDate,
    String? bodyRegion,
    String? orderingPhysicianId,
    String? performingPhysicianId,
    String? institutionId,
    String? clinicalIndication,
    String? findings,
    String? conclusion,
    String? notes,
    String? filePath,
    String? fileName,
  }) async {
    final dio = ref.read(dioProvider);
    final serverUrl = ref.read(serverConfigProvider).valueOrNull ?? '';
    try {
      final fields = <String, dynamic>{
        'patient_id': patientId,
        'study_type': studyType,
        'study_date': studyDate.toIso8601String(),
        if (bodyRegion != null && bodyRegion.isNotEmpty)
          'body_region': bodyRegion,
        if (orderingPhysicianId != null)
          'ordering_physician_id': orderingPhysicianId,
        if (performingPhysicianId != null)
          'performing_physician_id': performingPhysicianId,
        if (institutionId != null) 'institution_id': institutionId,
        if (clinicalIndication != null && clinicalIndication.isNotEmpty)
          'clinical_indication': clinicalIndication,
        if (findings != null && findings.isNotEmpty) 'findings': findings,
        if (conclusion != null && conclusion.isNotEmpty)
          'conclusion': conclusion,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      if (filePath != null && fileName != null) {
        fields['attachment'] = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      }
      final formData = FormData.fromMap(fields);
      final response = await dio.post<Map<String, dynamic>>(
        '$serverUrl/diagnostic-studies',
        data: formData,
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        final study = DiagnosticStudy.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        final current = state.valueOrNull ?? [];
        state = AsyncValue.data([study, ...current]);
      } else {
        await refresh();
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> saveStudy(
    String id, {
    required String patientId,
    required String studyType,
    required DateTime studyDate,
    String? bodyRegion,
    String? orderingPhysicianId,
    String? performingPhysicianId,
    String? institutionId,
    String? clinicalIndication,
    String? findings,
    String? conclusion,
    String? notes,
    String? filePath,
    String? fileName,
  }) async {
    final dio = ref.read(dioProvider);
    final serverUrl = ref.read(serverConfigProvider).valueOrNull ?? '';
    try {
      final fields = <String, dynamic>{
        'patient_id': patientId,
        'study_type': studyType,
        'study_date': studyDate.toIso8601String(),
        if (bodyRegion != null && bodyRegion.isNotEmpty)
          'body_region': bodyRegion,
        if (orderingPhysicianId != null)
          'ordering_physician_id': orderingPhysicianId,
        if (performingPhysicianId != null)
          'performing_physician_id': performingPhysicianId,
        if (institutionId != null) 'institution_id': institutionId,
        if (clinicalIndication != null && clinicalIndication.isNotEmpty)
          'clinical_indication': clinicalIndication,
        if (findings != null && findings.isNotEmpty) 'findings': findings,
        if (conclusion != null && conclusion.isNotEmpty)
          'conclusion': conclusion,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      if (filePath != null && fileName != null) {
        fields['attachment'] = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      }
      final formData = FormData.fromMap(fields);
      final response = await dio.put<Map<String, dynamic>>(
        '$serverUrl/diagnostic-studies/$id',
        data: formData,
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        final updated = DiagnosticStudy.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        final current = state.valueOrNull ?? [];
        state = AsyncValue.data(
          current.map((s) => s.id == id ? updated : s).toList(),
        );
      } else {
        await refresh();
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> delete(String id) async {
    final api = DiagnosticStudyApi(ref.read(dioProvider));
    try {
      await api.deleteStudy(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((s) => s.id != id).toList());
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
Future<DiagnosticStudy> diagnosticStudyDetail(Ref ref, String studyId) async {
  final api = DiagnosticStudyApi(ref.watch(dioProvider));
  final response = await api.getStudy(studyId);
  return response.data!;
}
