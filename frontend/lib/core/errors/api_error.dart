import 'package:dio/dio.dart';

class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    this.details,
    this.traceId,
    this.helpUrl,
    this.statusCode,
  });

  factory ApiError.fromDioException(DioException exception) {
    final response = exception.response;
    if (response != null) {
      return ApiError.fromResponse(response);
    }
    return ApiError(
      code: 'NETWORK_ERROR',
      message: exception.message ?? 'Network request failed',
    );
  }

  factory ApiError.fromResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) {
      final detail = data['detail'];
      return ApiError(
        code: _stringValue(data['code']) ?? _fallbackCode(response.statusCode),
        message:
            _stringValue(data['message']) ??
            _stringValue(detail) ??
            'Request failed',
        details: data['details'] ?? (detail is Map ? detail : null),
        traceId: _stringValue(data['trace_id'] ?? data['traceId']),
        helpUrl: _stringValue(data['help_url'] ?? data['helpUrl']),
        statusCode: response.statusCode,
      );
    }
    return ApiError(
      code: _fallbackCode(response.statusCode),
      message: 'Request failed',
      statusCode: response.statusCode,
    );
  }

  final String code;
  final String message;
  final Object? details;
  final String? traceId;
  final String? helpUrl;
  final int? statusCode;

  @override
  String toString() => 'ApiError($code): $message';

  static String? _stringValue(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  static String _fallbackCode(int? statusCode) {
    return statusCode == null ? 'UNKNOWN_ERROR' : 'HTTP_$statusCode';
  }
}
