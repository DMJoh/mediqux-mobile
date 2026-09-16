import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/lab_panel/lab_panel.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/services/lab_report_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lab_report_provider.g.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

@Riverpod(keepAlive: true)
class LabReports extends _$LabReports {
  @override
  Future<List<LabReport>> build() async {
    if (ref.watch(authProvider).value == null) return [];
    await ref.watch(serverConfigProvider.future);
    final api = LabReportApi(ref.read(dioProvider));
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
    required String testType,
    required DateTime testDate,
    required String filePath,
    required String fileName,
    String? appointmentId,
    String? institutionId,
    String? performedById,
  }) async {
    final dio = ref.read(dioProvider);
    final serverUrl = ref.read(serverConfigProvider).value ?? '';
    try {
      final formData = FormData.fromMap({
        'patientId': patientId,
        'testName': testName,
        'testType': testType,
        'testDate': _dateFmt.format(testDate),
        if (appointmentId != null) 'appointmentId': appointmentId,
        if (institutionId != null) 'institutionId': institutionId,
        if (performedById != null) 'performedById': performedById,
        'pdfFile': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      await dio.post<Map<String, dynamic>>(
        '$serverUrl/test-results/upload',
        data: formData,
      );
      await refresh();
    } on DioException {
      rethrow;
    }
  }

  Future<void> create({
    required String patientId,
    required String testName,
    required String testType,
    required DateTime testDate,
    String? appointmentId,
    String? institutionId,
    String? performedById,
    List<Map<String, dynamic>>? labValues,
  }) async {
    final dio = ref.read(dioProvider);
    final serverUrl = ref.read(serverConfigProvider).value ?? '';
    try {
      final body = <String, dynamic>{
        'patient_id': patientId,
        'test_name': testName,
        'test_type': testType,
        'test_date': _dateFmt.format(testDate),
        if (appointmentId != null) 'appointment_id': appointmentId,
        if (institutionId != null) 'institution_id': institutionId,
        if (performedById != null) 'performed_by_id': performedById,
        if (labValues != null && labValues.isNotEmpty) 'lab_values': labValues,
      };
      final response = await dio.post<Map<String, dynamic>>(
        '$serverUrl/test-results',
        data: body,
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        final report = LabReport.fromJson(data['data'] as Map<String, dynamic>);
        final current = state.value ?? [];
        state = AsyncValue.data([report, ...current]);
      } else {
        await refresh();
      }
    } on DioException {
      rethrow;
    }
  }

  Future<void> saveEdit({
    required String id,
    required String testName,
    required String testType,
    required DateTime testDate,
    String? appointmentId,
    String? institutionId,
    String? performedById,
    List<Map<String, dynamic>>? labValues,
  }) async {
    final dio = ref.read(dioProvider);
    final serverUrl = ref.read(serverConfigProvider).value ?? '';
    try {
      final body = <String, dynamic>{
        'test_name': testName,
        'test_type': testType,
        'test_date': _dateFmt.format(testDate),
        'appointment_id': appointmentId,
        'institution_id': institutionId,
        'performed_by_id': performedById,
        'lab_values': labValues ?? [],
      };
      await dio.put<Map<String, dynamic>>(
        '$serverUrl/test-results/$id',
        data: body,
      );
      await refresh();
    } on DioException {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final api = LabReportApi(ref.read(dioProvider));
    try {
      await api.deleteLabReport(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((r) => r.id != id).toList());
    } on DioException {
      rethrow;
    }
  }
}

@riverpod
Future<LabReport> labReportDetail(Ref ref, String reportId) async {
  final api = LabReportApi(ref.watch(dioProvider));
  final response = await api.getLabReport(reportId);
  return response.data!;
}

@riverpod
Future<List<LabPanel>> labPanels(Ref ref) async {
  if (ref.watch(authProvider).value == null) return [];
  final dio = ref.watch(dioProvider);
  final serverUrl = ref.watch(serverConfigProvider).value ?? '';
  final response = await dio.get<dynamic>('$serverUrl/test-results/panels');
  final data = response.data;
  if (data is! List) return [];
  return data.map((e) => LabPanel.fromJson(e as Map<String, dynamic>)).toList();
}
