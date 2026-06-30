import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_api/mavra_api.dart' as generated;
import 'package:mavra_frontend/core/config/app_config.dart';
import 'package:mavra_frontend/core/realtime/realtime_client.dart';
import 'package:mavra_frontend/features/events/data/events_api.dart';
import 'package:mavra_frontend/features/events/domain/event_models.dart';

void main() {
  test(
    'GeneratedEventRepository maps list fields and query parameters',
    () async {
      final requests = <RequestOptions>[];
      final client = generated.MavraApi(basePathOverride: 'https://api.example')
        ..dio.httpClientAdapter = _Adapter((options) {
          requests.add(options);
          return _jsonResponse(200, {
            'items': [_eventJson()],
            'total': 24,
            'page': 2,
            'page_size': 50,
          });
        });
      final repository = GeneratedEventRepository(
        config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
        client: client,
      );

      final page = await repository.listEvents(
        query: EventQuery(
          filter: EventFilter.platform,
          eventType: 'profile.challenge',
          category: 'crawler',
          severity: 'warning',
          source: 'worker',
          keyword: 'challenge',
          startAt: DateTime.utc(2026, 6, 1),
          endAt: DateTime.utc(2026, 6, 18),
          page: 2,
          pageSize: 50,
        ),
      );

      final request = requests.single;
      expect(request.path, '/api/v1/events');
      expect(request.queryParameters['kind'], 'platform');
      expect(request.queryParameters['event_type'], 'profile.challenge');
      expect(request.queryParameters['category'], 'crawler');
      expect(request.queryParameters['severity'], 'warning');
      expect(request.queryParameters['source'], 'worker');
      expect(request.queryParameters['keyword'], 'challenge');
      expect(request.queryParameters['page'], 2);
      expect(request.queryParameters['page_size'], 50);

      expect(page.total, 24);
      expect(page.page, 2);
      expect(page.pageSize, 50);
      expect(page.items.single, isA<EventFeedItem>());
      final item = page.items.single;
      expect(item.kind, EventKind.platform);
      expect(item.eventType, 'profile.challenge');
      expect(item.status, 'delivered');
      expect(item.userId, 42);
      expect(item.entityType, 'profile');
      expect(item.entityId, 'boss-main');
      expect(item.traceId, 'trace-123');
      expect(item.payload, {'reason': 'captcha', 'attempts': 2});
    },
  );

  test('GeneratedEventRepository maps and filters realtime payloads', () async {
    final realtimeClient = _FakeRealtimeClient();
    final repository = GeneratedEventRepository(
      config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
      client: generated.MavraApi(basePathOverride: 'https://api.example'),
      realtimeClient: realtimeClient,
    );

    final expectation = expectLater(
      repository.watchEvents(
        query: const EventQuery(
          filter: EventFilter.platform,
          severity: 'warning',
          keyword: 'profile',
        ),
      ),
      emits(
        isA<EventFeedItem>()
            .having((item) => item.id, 'id', 'evt-2')
            .having((item) => item.kind, 'kind', EventKind.platform)
            .having((item) => item.status, 'status', 'delivered')
            .having((item) => item.userId, 'userId', 42)
            .having((item) => item.entityType, 'entityType', 'profile')
            .having((item) => item.entityId, 'entityId', 'boss-main')
            .having((item) => item.traceId, 'traceId', 'trace-123')
            .having((item) => item.payload, 'payload', {
              'reason': 'captcha',
              'attempts': 2,
            }),
      ),
    );

    realtimeClient.emit(
      const RealtimeMessage(
        type: 'event',
        payload: {
          'id': 'evt-1',
          'kind': 'audit',
          'severity': 'info',
          'message': 'User logged in',
        },
      ),
    );
    realtimeClient.emit(
      RealtimeMessage(
        type: 'event',
        payload: _eventJson(id: 'evt-2'),
      ),
    );

    await expectation;
    expect(realtimeClient.channels, ['events']);
  });

  test(
    'GeneratedEventRepository polls events when no realtime client is injected',
    () async {
      final requests = <RequestOptions>[];
      final client = generated.MavraApi(basePathOverride: 'https://api.example')
        ..dio.httpClientAdapter = _Adapter((options) {
          requests.add(options);
          return _jsonResponse(200, {
            'items': [_eventJson(id: 'evt-polled')],
            'total': 1,
            'page': 1,
            'page_size': 20,
          });
        });
      final repository = GeneratedEventRepository(
        config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
        client: client,
      );

      final event = await repository.watchEvents().first;

      expect(event.id, 'evt-polled');
      expect(requests.single.path, '/api/v1/events');
    },
  );
}

Map<String, Object?> _eventJson({String id = 'evt-1'}) {
  return {
    'id': id,
    'kind': 'platform',
    'event_type': 'profile.challenge',
    'category': 'crawler',
    'severity': 'warning',
    'message': 'Boss profile challenge detected',
    'occurred_at': '2026-06-17T09:00:00Z',
    'source': 'worker',
    'status': 'delivered',
    'user_id': 42,
    'entity_type': 'profile',
    'entity_id': 'boss-main',
    'trace_id': 'trace-123',
    'payload': {'reason': 'captcha', 'attempts': 2},
  };
}

Future<ResponseBody> _jsonResponse(int statusCode, Object data) async {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRealtimeClient extends RealtimeClient {
  final _controller = StreamController<RealtimeMessage>.broadcast();
  final channels = <String>[];

  @override
  Stream<RealtimeMessage> connect(String channel) {
    channels.add(channel);
    return _controller.stream;
  }

  void emit(RealtimeMessage message) => _controller.add(message);
}
