import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/providers/storage_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final serverUrl = ref.watch(serverConfigProvider).valueOrNull ?? '';

  final dio = Dio(
    BaseOptions(
      baseUrl: serverUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );

  return dio;
});
