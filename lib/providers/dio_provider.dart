import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/providers/refresh_coordinator_provider.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/providers/session_provider.dart';
import 'package:mediqux_mobile/providers/storage_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final serverUrl = ref.watch(serverConfigProvider).value ?? '';

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
        // OkHttp (NativeAdapter) caches GET responses by default; disable it.
        options.headers['Cache-Control'] = 'no-cache';
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final body = error.response?.data;
        // Backend returns 403 (not 401) for an expired token, with
        // `expired: true` in the body — a plain 403 without that flag means
        // the token is otherwise invalid and refreshing it would fail too.
        final isExpired =
            status == 403 && body is Map && body['expired'] == true;
        final isRecoverable = status == 401 || isExpired;
        if (isRecoverable) {
          final alreadyRefreshed =
              error.requestOptions.extra['_refreshed'] == true;
          if (!alreadyRefreshed) {
            final newToken = await ref
                .read(refreshCoordinatorProvider.notifier)
                .refresh();
            if (newToken != null) {
              try {
                final retryOpts = error.requestOptions.copyWith(
                  extra: {...error.requestOptions.extra, '_refreshed': true},
                );
                retryOpts.headers['Authorization'] = 'Bearer $newToken';
                final retryResponse = await dio.fetch<dynamic>(retryOpts);
                return handler.resolve(retryResponse);
              } on Object {
                // Retry with the fresh token also failed — fall through.
              }
            }
          }
          await storage.clearAuth();
          ref.read(sessionVersionProvider.notifier).increment();
        } else if (status == 403) {
          await storage.clearAuth();
          ref.read(sessionVersionProvider.notifier).increment();
        }
        return handler.next(error);
      },
    ),
  );

  // Retry GET requests once after 2 s on connection-level failures.
  // This handles Android Doze: network is briefly unavailable right after
  // the phone wakes and the app starts, then stabilises within seconds.
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final opts = error.requestOptions;
        final isGet = opts.method == 'GET';
        final alreadyRetried = opts.extra['_retried'] == true;
        final isConnectError =
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.connectionError;
        if (isGet && isConnectError && !alreadyRetried) {
          await Future<void>.delayed(const Duration(seconds: 2));
          try {
            final retryOpts = opts.copyWith(
              extra: {...opts.extra, '_retried': true},
            );
            final response = await dio.fetch<dynamic>(retryOpts);
            return handler.resolve(response);
          } on Object {
            // retry also failed — fall through to original error
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
