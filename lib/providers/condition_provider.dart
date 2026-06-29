import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/models/condition/condition.dart';
import 'package:mediqux_mobile/models/condition/condition_request.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/services/condition_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'condition_provider.g.dart';

@Riverpod(keepAlive: true)
class Conditions extends _$Conditions {
  @override
  Future<List<Condition>> build() async {
    final api = ConditionApi(ref.watch(dioProvider));
    final response = await api.getConditions();
    return response.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ConditionApi(ref.read(dioProvider));
      final response = await api.getConditions();
      return response.data ?? [];
    });
  }

  Future<Condition> create(ConditionRequest request) async {
    final api = ConditionApi(ref.read(dioProvider));
    try {
      final response = await api.createCondition(request);
      final condition = response.data!;
      final current = state.valueOrNull ?? [];
      final updated = [...current, condition]
        ..sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(updated);
      return condition;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Condition> saveCondition(String id, ConditionRequest request) async {
    final api = ConditionApi(ref.read(dioProvider));
    try {
      final response = await api.updateCondition(id, request);
      final updated = response.data!;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((c) => c.id == id ? updated : c).toList(),
      );
      return updated;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> delete(String id) async {
    final api = ConditionApi(ref.read(dioProvider));
    try {
      await api.deleteCondition(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((c) => c.id != id).toList());
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
Future<Condition> conditionDetail(Ref ref, String conditionId) async {
  final api = ConditionApi(ref.watch(dioProvider));
  final response = await api.getCondition(conditionId);
  return response.data!;
}
