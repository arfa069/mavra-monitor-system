import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_api/mavra_api.dart' as generated;
import 'package:mavra_frontend/core/config/app_config.dart';
import 'package:mavra_frontend/core/realtime/realtime_client.dart';
import 'package:mavra_frontend/features/analytics/data/analytics_api.dart';
import 'package:mavra_frontend/features/analytics/domain/analytics_models.dart';

void main() {
  test('GeneratedAnalyticsRepository calls dashboard parity APIs', () async {
    final requests = <RequestOptions>[];
    final client = generated.MavraApi(basePathOverride: 'https://api.example')
      ..dio.httpClientAdapter = _Adapter((options) {
        requests.add(options);
        return _jsonResponse(200, _responseFor(options));
      });
    final repository = GeneratedAnalyticsRepository(
      config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
      client: client,
    );

    final overview = await repository.loadOverview(
      days: 30,
      includeAdmin: true,
    );

    expect(overview.userKpi.totalProducts, 12);
    expect(overview.systemKpi?.successRate, 0.96);
    expect(overview.userTrends.map((section) => section.type), const [
      AnalyticsTrendType.platformProducts,
      AnalyticsTrendType.price,
      AnalyticsTrendType.priceChange,
      AnalyticsTrendType.platformJobs,
      AnalyticsTrendType.jobs,
      AnalyticsTrendType.jobMatches,
    ]);
    expect(overview.systemTrends.map((section) => section.type), const [
      AnalyticsTrendType.platformSuccess,
      AnalyticsTrendType.crawlFailures,
    ]);
    expect(overview.recentAlerts.single.platform, 'taobao');
    expect(overview.recentAlerts.single.active, isTrue);

    final trendRequests = requests
        .where((request) => request.path == '/api/v1/dashboard/trends')
        .toList();
    expect(trendRequests.map((request) => request.queryParameters['type']), [
      'platform_products',
      'price',
      'price_change',
      'platform_jobs',
      'jobs',
      'job_matches',
      'platform_success',
      'crawl_failures',
    ]);
    expect(
      trendRequests.map((request) => request.queryParameters['days']),
      everyElement(30),
    );

    final alertsRequest = requests.singleWhere(
      (request) => request.path == '/api/v1/dashboard/alerts/recent',
    );
    expect(alertsRequest.queryParameters['limit'], 10);
  });

  test(
    'GeneratedAnalyticsRepository skips admin-only calls for limited users',
    () async {
      final requests = <RequestOptions>[];
      final client = generated.MavraApi(basePathOverride: 'https://api.example')
        ..dio.httpClientAdapter = _Adapter((options) {
          requests.add(options);
          return _jsonResponse(200, _responseFor(options));
        });
      final repository = GeneratedAnalyticsRepository(
        config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
        client: client,
      );

      final overview = await repository.loadOverview(
        days: 7,
        includeAdmin: false,
      );

      expect(overview.systemTrends, isEmpty);
      expect(overview.recentAlerts, isEmpty);
      expect(
        requests.any(
          (request) => request.path == '/api/v1/dashboard/alerts/recent',
        ),
        isFalse,
      );
      expect(
        requests
            .where((request) => request.path == '/api/v1/dashboard/trends')
            .map((request) => request.queryParameters['type']),
        isNot(contains('platform_success')),
      );
    },
  );

  test(
    'GeneratedAnalyticsRepository keeps sections when one trend fails',
    () async {
      final client = generated.MavraApi(basePathOverride: 'https://api.example')
        ..dio.httpClientAdapter = _Adapter((options) {
          if (options.path == '/api/v1/dashboard/trends' &&
              options.queryParameters['type'] == 'price') {
            return _jsonResponse(500, {'message': 'trend unavailable'});
          }
          return _jsonResponse(200, _responseFor(options));
        });
      final repository = GeneratedAnalyticsRepository(
        config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
        client: client,
      );

      final overview = await repository.loadOverview(
        days: 30,
        includeAdmin: true,
      );

      final priceTrend = overview.userTrends.singleWhere(
        (section) => section.type == AnalyticsTrendType.price,
      );
      expect(priceTrend.series, isEmpty);
      expect(overview.userTrends.length, 6);
    },
  );

  test(
    'GeneratedAnalyticsRepository maps kpi_update realtime messages',
    () async {
      final realtimeClient = _FakeRealtimeClient();
      final repository = GeneratedAnalyticsRepository(
        config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
        client: generated.MavraApi(basePathOverride: 'https://api.example'),
        realtimeClient: realtimeClient,
      );

      final expectation = expectLater(
        repository.watchKpiUpdates(),
        emits(
          isA<AnalyticsKpiSnapshot>()
              .having((snapshot) => snapshot.user.totalProducts, 'products', 88)
              .having(
                (snapshot) => snapshot.system?.successRate,
                'success rate',
                0.91,
              ),
        ),
      );

      realtimeClient.emit(
        const RealtimeMessage(
          type: 'message',
          payload: {
            'event': 'kpi_update',
            'data': {
              'total_products': 88,
              'price_drops_today': 5,
              'new_jobs_today': 6,
              'match_count': 7,
              'crawl_count_today': 9,
            },
            'system': {
              'total_users': 4,
              'total_crawls': 90,
              'success_rate': 0.91,
              'active_alerts': 3,
              'disk_usage': 0.45,
              'memory_usage': 0.62,
            },
          },
        ),
      );

      await expectation;
    },
  );
}

Object _responseFor(RequestOptions options) {
  if (options.path == '/api/v1/dashboard/trends') {
    return _trendResponse(options.queryParameters['type'].toString());
  }
  return switch (options.path) {
    '/api/v1/dashboard/kpi' => {
      'user': {
        'total_products': 12,
        'price_drops_today': 2,
        'new_jobs_today': 4,
        'match_count': 5,
        'crawl_count_today': 9,
      },
      'system': {
        'total_users': 3,
        'total_crawls': 45,
        'success_rate': 0.96,
        'active_alerts': 2,
        'disk_usage': 0.41,
        'memory_usage': 0.68,
      },
    },
    '/api/v1/dashboard/alerts/recent' => [
      {
        'id': 1,
        'product_id': 7,
        'alert_type': 'price_drop',
        'message': 'Taobao rice cooker dropped 12%',
        'active': true,
        'created_at': '2026-06-17T08:00:00Z',
        'product_title': 'Taobao rice cooker',
        'platform': 'taobao',
      },
    ],
    _ => throw StateError('Unexpected path ${options.path}'),
  };
}

Object _trendResponse(String type) {
  return {
    'labels': ['Mon', 'Tue'],
    'datasets': [
      {
        'label': type,
        'data': [
          {'label': 'Mon', 'value': type == 'price_change' ? -6 : 12},
          {'label': 'Tue', 'value': 18},
        ],
      },
    ],
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

  @override
  Stream<RealtimeMessage> connect(String channel) => _controller.stream;

  void emit(RealtimeMessage message) => _controller.add(message);
}
