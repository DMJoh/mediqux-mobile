import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/condition/condition.dart';
import 'package:mediqux_mobile/models/condition/condition_request.dart';
import 'package:mediqux_mobile/providers/auth_provider.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/services/condition_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'condition_provider.g.dart';

@Riverpod(keepAlive: true)
class Conditions extends _$Conditions {
  @override
  Future<List<Condition>> build() async {
    if (ref.watch(authProvider).value == null) return [];
    await ref.watch(serverConfigProvider.future);
    final api = ConditionApi(ref.read(dioProvider));
    final response = await api.getConditions();
    return response.data ?? [];
  }

  Future<void> refresh() async {
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
      final current = state.value ?? [];
      final updated = [...current, condition]
        ..sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(updated);
      return condition;
    } on DioException {
      rethrow;
    }
  }

  Future<Condition> saveCondition(String id, ConditionRequest request) async {
    final api = ConditionApi(ref.read(dioProvider));
    try {
      final response = await api.updateCondition(id, request);
      final updated = response.data!;
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((c) => c.id == id ? updated : c).toList(),
      );
      return updated;
    } on DioException {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final api = ConditionApi(ref.read(dioProvider));
    try {
      await api.deleteCondition(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((c) => c.id != id).toList());
    } on DioException {
      rethrow;
    }
  }
}

@riverpod
Future<Condition> conditionDetail(Ref ref, String conditionId) async {
  final api = ConditionApi(ref.watch(dioProvider));
  final response = await api.getCondition(conditionId);
  return response.data!;
}
