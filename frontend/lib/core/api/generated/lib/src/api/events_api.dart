//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:mavra_api/src/api_util.dart';
import 'package:mavra_api/src/model/event_center_list_response.dart';
import 'package:mavra_api/src/model/http_validation_error.dart';

class EventsApi {

  final Dio _dio;

  final Serializers _serializers;

  const EventsApi(this._dio, this._serializers);

  /// List Events
  /// Return a unified paginated event-center list.
  ///
  /// Parameters:
  /// * [kind] 
  /// * [eventType] 
  /// * [category] 
  /// * [severity] 
  /// * [source_] 
  /// * [keyword] 
  /// * [startAt] 
  /// * [endAt] 
  /// * [page] 
  /// * [pageSize] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [EventCenterListResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<EventCenterListResponse>> eventsListEvents({ 
    String? kind = 'all',
    String? eventType,
    String? category,
    String? severity,
    String? source_,
    String? keyword,
    DateTime? startAt,
    DateTime? endAt,
    int? page = 1,
    int? pageSize = 20,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/events';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      if (kind != null) r'kind': encodeQueryParameter(_serializers, kind, const FullType(String)),
      r'event_type': encodeQueryParameter(_serializers, eventType, const FullType(String)),
      r'category': encodeQueryParameter(_serializers, category, const FullType(String)),
      r'severity': encodeQueryParameter(_serializers, severity, const FullType(String)),
      r'source': encodeQueryParameter(_serializers, source_, const FullType(String)),
      r'keyword': encodeQueryParameter(_serializers, keyword, const FullType(String)),
      r'start_at': encodeQueryParameter(_serializers, startAt, const FullType(DateTime)),
      r'end_at': encodeQueryParameter(_serializers, endAt, const FullType(DateTime)),
      if (page != null) r'page': encodeQueryParameter(_serializers, page, const FullType(int)),
      if (pageSize != null) r'page_size': encodeQueryParameter(_serializers, pageSize, const FullType(int)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    EventCenterListResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(EventCenterListResponse),
      ) as EventCenterListResponse;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<EventCenterListResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Stream Events
  /// Stream event-center updates over SSE.
  ///
  /// Parameters:
  /// * [kind] 
  /// * [eventType] 
  /// * [category] 
  /// * [severity] 
  /// * [source_] 
  /// * [keyword] 
  /// * [startAt] 
  /// * [endAt] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [String] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<String>> eventsStreamEvents({ 
    String? kind = 'all',
    String? eventType,
    String? category,
    String? severity,
    String? source_,
    String? keyword,
    DateTime? startAt,
    DateTime? endAt,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/events/stream';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      if (kind != null) r'kind': encodeQueryParameter(_serializers, kind, const FullType(String)),
      r'event_type': encodeQueryParameter(_serializers, eventType, const FullType(String)),
      r'category': encodeQueryParameter(_serializers, category, const FullType(String)),
      r'severity': encodeQueryParameter(_serializers, severity, const FullType(String)),
      r'source': encodeQueryParameter(_serializers, source_, const FullType(String)),
      r'keyword': encodeQueryParameter(_serializers, keyword, const FullType(String)),
      r'start_at': encodeQueryParameter(_serializers, startAt, const FullType(DateTime)),
      r'end_at': encodeQueryParameter(_serializers, endAt, const FullType(DateTime)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    String? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : rawResponse as String;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<String>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
