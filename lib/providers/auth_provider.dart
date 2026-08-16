import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mediqux_mobile/models/auth/login_request.dart';
import 'package:mediqux_mobile/models/user.dart';
import 'package:mediqux_mobile/providers/dio_provider.dart';
import 'package:mediqux_mobile/providers/session_provider.dart';
import 'package:mediqux_mobile/providers/storage_provider.dart';
import 'package:mediqux_mobile/services/auth_api.dart';
import 'package:mediqux_mobile/services/storage_service.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

Map<String, dynamic>? _jwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    var payload = parts[1];
    switch (payload.length % 4) {
      case 2:
        payload += '==';
      case 3:
        payload += '=';
    }
    return jsonDecode(utf8.decode(base64Url.decode(payload)))
        as Map<String, dynamic>;
  } on Object {
    return null;
  }
}

bool _isJwtExpired(String token) {
  final exp = _jwtPayload(token)?['exp'];
  if (exp == null) return false;
  return DateTime.now().millisecondsSinceEpoch > (exp as num).toInt() * 1000;
}

bool _isJwtExpiringSoon(String token) {
  final exp = _jwtPayload(token)?['exp'];
  if (exp == null) return false;
  final expiryMs = (exp as num).toInt() * 1000;
  final thresholdMs = const Duration(days: 3).inMilliseconds;
  return DateTime.now().millisecondsSinceEpoch > expiryMs - thresholdMs;
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<User?> build() async {
    ref.watch(sessionVersionProvider);
    final storage = ref.watch(storageServiceProvider);
    final token = await storage.readToken();
    if (token == null) return null;
    if (_isJwtExpired(token)) {
      await storage.clearAuth();
      return null;
    }
    if (_isJwtExpiringSoon(token)) {
      unawaited(_silentRefresh(storage));
    }
    return storage.readUser();
  }

  Future<void> _silentRefresh(StorageService storage) async {
    try {
      final api = AuthApi(ref.read(dioProvider));
      final response = await api.refresh();
      if (response.success && response.data != null) {
        await storage.saveToken(response.data!.token);
      }
    } on Object {
      // Refresh failed — current token is still valid; retry next open.
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    final storage = ref.read(storageServiceProvider);
    final api = AuthApi(ref.read(dioProvider));
    try {
      final response = await api.login(
        LoginRequest(username: username, password: password),
      );
      if (response.success && response.data != null) {
        await storage.saveToken(response.data!.token);
        await storage.saveUser(response.data!.user);
        state = AsyncValue.data(response.data!.user);
      } else {
        state = AsyncValue.error(
          response.error ?? 'Login failed',
          StackTrace.current,
        );
      }
    } on DioException catch (e, st) {
      state = AsyncValue.error(friendlyError(e), st);
    } on Object catch (_, st) {
      state = AsyncValue.error('An unexpected error occurred', st);
    }
  }

  Future<void> logout() async {
    await ref.read(storageServiceProvider).clearAuth();
    state = const AsyncValue.data(null);
  }
}
