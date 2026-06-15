import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single Dio instance for the whole app. Generous timeouts because audio
/// uploads + Gemini responses are sometimes slow on Indian mobile networks;
/// retry on transient 5xx and connection errors only.
Dio buildDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );
  dio.interceptors.add(_RetryInterceptor(dio));
  return dio;
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;
  static const int _maxAttempts = 3;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry = _isRetryable(err);
    final attempts = (err.requestOptions.extra['attempt'] as int?) ?? 1;

    if (!shouldRetry || attempts >= _maxAttempts) {
      return handler.next(err);
    }

    final delayMs = 400 * (1 << (attempts - 1)); // 400, 800, 1600
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    try {
      final opts = err.requestOptions..extra['attempt'] = attempts + 1;
      final response = await _dio.fetch<dynamic>(opts);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    final code = err.response?.statusCode ?? 0;
    return code == 502 || code == 503 || code == 504;
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = buildDio();
  ref.onDispose(dio.close);
  return dio;
});
