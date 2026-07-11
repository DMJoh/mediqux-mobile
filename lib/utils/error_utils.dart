import 'package:dio/dio.dart';

/// Converts any exception into a short, user-facing message.
String friendlyError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server is not responding. '
            'Check that it is running.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. '
            'Check the address and your connection.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          return 'Session expired. Please log in again.';
        }
        if (code != null) return 'Server returned an error ($code).';
        return 'Unexpected server response.';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error. Check your server configuration.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Check your connection.';
    }
  }
  return 'An unexpected error occurred.';
}
