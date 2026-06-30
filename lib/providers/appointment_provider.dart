import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/models/appointment/appointment_request.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/services/appointment_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appointment_provider.g.dart';

@Riverpod(keepAlive: true)
class Appointments extends _$Appointments {
  @override
  Future<List<Appointment>> build() async {
    final api = AppointmentApi(ref.watch(dioProvider));
    final response = await api.getAppointments();
    final data = response.data ?? []
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    return data;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = AppointmentApi(ref.read(dioProvider));
      final response = await api.getAppointments();
      final data = response.data ?? []
        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return data;
    });
  }

  Future<Appointment> create(AppointmentRequest request) async {
    final api = AppointmentApi(ref.read(dioProvider));
    try {
      final response = await api.createAppointment(request);
      final appointment = response.data!;
      final current = state.valueOrNull ?? [];
      final updated = [appointment, ...current];
      state = AsyncValue.data(updated);
      return appointment;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Appointment> saveAppointment(
    String id,
    AppointmentRequest request,
  ) async {
    final api = AppointmentApi(ref.read(dioProvider));
    try {
      final response = await api.updateAppointment(id, request);
      final updated = response.data!;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((a) => a.id == id ? updated : a).toList(),
      );
      return updated;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> delete(String id) async {
    final api = AppointmentApi(ref.read(dioProvider));
    try {
      await api.deleteAppointment(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((a) => a.id != id).toList());
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
Future<Appointment> appointmentDetail(Ref ref, String appointmentId) async {
  final api = AppointmentApi(ref.watch(dioProvider));
  final response = await api.getAppointment(appointmentId);
  return response.data!;
}
