import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/services/lab_report_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lab_report_provider.g.dart';

@Riverpod(keepAlive: true)
class LabReports extends _$LabReports {
  @override
  Future<List<LabReport>> build() async {
    final api = LabReportApi(ref.watch(dioProvider));
    final response = await api.getLabReports();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final api = LabReportApi(ref.read(dioProvider));
      final response = await api.getLabReports();
      return response.data ?? [];
    });
  }

  Future<void> upload({
    required String patientId,
    required String testName,
    required DateTime testDate,
    required String filePath,
    required String fileName,
    String? appointmentId,
    String? notes,
  }) async {
    final dio = ref.read(dioProvider);
    final serverUrl = ref.read(serverConfigProvider).valueOrNull ?? '';
    try {
      final formData = FormData.fromMap({
        'patient_id': patientId,
        'test_name': testName,
        'test_date': testDate.toIso8601String(),
        if (appointmentId != null) 'appointment_id': appointmentId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'pdfFile': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await dio.post<Map<String, dynamic>>(
        '$serverUrl/test-results/upload',
        data: formData,
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        final report = LabReport.fromJson(data['data'] as Map<String, dynamic>);
        final current = state.valueOrNull ?? [];
        state = AsyncValue.data([report, ...current]);
      } else {
        await refresh();
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> create({
    required String patientId,
    required String testName,
    required DateTime testDate,
    String? appointmentId,
    String? notes,
    String? status,
  }) async {
    final dio = ref.read(dioProvider);
    final serverUrl = ref.read(serverConfigProvider).valueOrNull ?? '';
    try {
      final body = <String, dynamic>{
        'patient_id': patientId,
        'test_name': testName,
        'test_date': testDate.toIso8601String(),
        if (appointmentId != null) 'appointment_id': appointmentId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (status != null) 'status': status,
      };
      final response = await dio.post<Map<String, dynamic>>(
        '$serverUrl/test-results',
        data: body,
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        final report = LabReport.fromJson(data['data'] as Map<String, dynamic>);
        final current = state.valueOrNull ?? [];
        state = AsyncValue.data([report, ...current]);
      } else {
        await refresh();
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> delete(String id) async {
    final api = LabReportApi(ref.read(dioProvider));
    try {
      await api.deleteLabReport(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((r) => r.id != id).toList());
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
Future<LabReport> labReportDetail(Ref ref, String reportId) async {
  final api = LabReportApi(ref.watch(dioProvider));
  final response = await api.getLabReport(reportId);
  return response.data!;
}
