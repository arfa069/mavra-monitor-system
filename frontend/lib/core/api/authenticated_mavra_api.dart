import 'package:dio/dio.dart';
import 'package:mavra_api/mavra_api.dart' as generated;

import '../auth/auth_repository.dart';
import '../config/app_config.dart';

generated.MavraApi createAuthenticatedMavraApi({
  required AppConfig config,
  required AuthRepository authRepository,
}) {
  final client = generated.MavraApi(
    basePathOverride: serviceRootFromApiBaseUrl(config.apiBaseUrl),
  );
  Future<bool>? refreshFlight;

  client.dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        _omitEmptyQueryParameters(options);
        final token = await authRepository.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final requestOptions = error.requestOptions;
        final shouldRefresh =
            error.response?.statusCode == 401 &&
            requestOptions.extra['mavraRetry'] != true &&
            !_isAuthEndpoint(requestOptions.path);

        if (!shouldRefresh) {
          handler.next(error);
          return;
        }

        final existing = refreshFlight;
        final refreshed = await (existing ??
            (refreshFlight = authRepository.refreshSession().whenComplete(() {
              refreshFlight = null;
            })));
        if (!refreshed) {
          handler.next(error);
          return;
        }

        requestOptions.extra['mavraRetry'] = true;
        final token = await authRepository.getAccessToken();
        if (token != null && token.isNotEmpty) {
          requestOptions.headers['Authorization'] = 'Bearer $token';
        }

        try {
          final retryResponse = await client.dio.fetch<dynamic>(requestOptions);
          handler.resolve(retryResponse);
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    ),
  );
  return client;
}

void _omitEmptyQueryParameters(RequestOptions options) {
  options.queryParameters.removeWhere((_, value) => _isEmptyQueryValue(value));
}

bool _isEmptyQueryValue(Object? value) {
  return value == null ||
      value == '' ||
      (value is Iterable<Object?> && value.isEmpty);
}

bool _isAuthEndpoint(String path) {
  return path.contains('/auth/login') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/logout');
}

String serviceRootFromApiBaseUrl(String apiBaseUrl) {
  const apiPrefix = '/api/v1';
  final normalized = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;
  if (normalized.endsWith(apiPrefix)) {
    return normalized.substring(0, normalized.length - apiPrefix.length);
  }
  return normalized;
}
