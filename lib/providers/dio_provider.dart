import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/providers/server_provider.dart';
import 'package:mediqux_mobile/providers/session_provider.dart';
import 'package:mediqux_mobile/providers/storage_provider.dart';
import 'package:mediqux_mobile/services/auth_api.dart';

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
        // OkHttp (NativeAdapter) caches GET responses by default; disable it.
        options.headers['Cache-Control'] = 'no-cache';
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final alreadyRefreshed =
              error.requestOptions.extra['_refreshed'] == true;
          if (!alreadyRefreshed) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: serverUrl));
              final oldToken = await storage.readToken();
              if (oldToken != null) {
                refreshDio.options.headers['Authorization'] =
                    'Bearer $oldToken';
              }
              final api = AuthApi(refreshDio);
              final response = await api.refresh();
              if (response.success && response.data != null) {
                await storage.saveToken(response.data!.token);
                final retryOpts = error.requestOptions.copyWith(
                  extra: {...error.requestOptions.extra, '_refreshed': true},
                );
                retryOpts.headers['Authorization'] =
                    'Bearer ${response.data!.token}';
                final retryResponse = await dio.fetch<dynamic>(retryOpts);
                return handler.resolve(retryResponse);
              }
            } on Object {
              // Refresh failed — fall through to logout.
            }
          }
          await storage.clearAuth();
          ref.read(sessionVersionProvider.notifier).state++;
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
