import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sentry_dio/sentry_dio.dart';

import '../auth/auth_repository.dart';
import '../config/app_config.dart';
import '../errors/api_error.dart';

class MavraApiClient {
  MavraApiClient({
    required AppConfig config,
    required this.authRepository,
    Dio? dio,
  }) : dio = dio ?? Dio(BaseOptions(baseUrl: config.apiBaseUrl)) {
    this.dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: _attachBearerToken,
        onError: _handleAuthError,
      ),
    );
    this.dio.addSentry();
  }

  final Dio dio;
  final AuthRepository authRepository;

  Future<bool>? _refreshFlight;

  Future<void> _attachBearerToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await authRepository.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _handleAuthError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final response = error.response;
    final requestOptions = error.requestOptions;
    final shouldRefresh =
        response?.statusCode == 401 &&
        requestOptions.extra['mavraRetry'] != true &&
        !_isAuthEndpoint(requestOptions.path);

    if (!shouldRefresh) {
      handler.next(error);
      return;
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) {
      await authRepository.logout();
      handler.next(error);
      return;
    }

    requestOptions.extra['mavraRetry'] = true;
    final token = await authRepository.getAccessToken();
    if (token != null && token.isNotEmpty) {
      requestOptions.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final retryResponse = await dio.fetch<dynamic>(requestOptions);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  ApiError mapError(DioException exception) {
    return ApiError.fromDioException(exception);
  }

  Future<bool> _refreshOnce() {
    final existing = _refreshFlight;
    if (existing != null) {
      return existing;
    }
    final refresh = authRepository.refreshSession().whenComplete(() {
      _refreshFlight = null;
    });
    _refreshFlight = refresh;
    return refresh;
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout');
  }
}
