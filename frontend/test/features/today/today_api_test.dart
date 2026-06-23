import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_api/mavra_api.dart' as generated;
import 'package:mavra_frontend/core/config/app_config.dart';
import 'package:mavra_frontend/features/today/data/today_api.dart';
import 'package:mavra_frontend/features/today/domain/today_models.dart';

void main() {
  test('buildTodaySnapshot maps price, job, and home signals', () {
    final snapshot = buildTodaySnapshot(
      const TodaySourceData(
        kpi: TodayKpiSnapshot(
          totalProducts: 5,
          priceDropsToday: 2,
          newJobsToday: 1,
          matchCount: 3,
          crawlCountToday: 9,
        ),
        products: [
          TodayProductSignal(id: 1, title: '米家电饭煲', platform: 'taobao'),
        ],
        jobMatches: [
          TodayJobSignal(
            id: 7,
            score: 92,
            title: 'Flutter 工程师',
            company: 'Mavra Labs',
            location: '上海',
          ),
        ],
        home: TodayHomeSignal(
          configured: true,
          connected: false,
          unavailableCount: 2,
          activeCount: 10,
        ),
      ),
    );

    expect(snapshot.headline, '今天只提醒 3 件事。');
    expect(snapshot.subhead, '其他事情都在安静运行，你可以先看最值得注意的变化。');
    expect(snapshot.quietScore, 30);
    expect(snapshot.attentionItems.map((item) => item.kind), [
      TodayAttentionKind.price,
      TodayAttentionKind.job,
      TodayAttentionKind.home,
    ]);
    expect(snapshot.attentionItems.first.title, '米家电饭煲 到了心理价位');
    expect(snapshot.attentionItems[1].description, 'Mavra Labs · 上海');
    expect(snapshot.moduleStatuses.map((status) => status.label), [
      '价格看守',
      '职位雷达',
      '家里设备',
    ]);
    expect(snapshot.moduleStatuses.last.state, TodayStatusState.attention);
  });

  test('buildTodaySnapshot maps the quiet state', () {
    final snapshot = buildTodaySnapshot(
      const TodaySourceData(
        kpi: TodayKpiSnapshot(
          totalProducts: 2,
          priceDropsToday: 0,
          newJobsToday: 0,
          matchCount: 0,
          crawlCountToday: 1,
        ),
        products: [],
        jobMatches: [],
        home: TodayHomeSignal(
          configured: true,
          connected: true,
          unavailableCount: 0,
          activeCount: 8,
        ),
      ),
    );

    expect(snapshot.headline, '今天很安静，Mavra 会继续帮你看着。');
    expect(snapshot.attentionItems, isEmpty);
    expect(
      snapshot.moduleStatuses.map((status) => status.state),
      everyElement(TodayStatusState.quiet),
    );
  });

  test('GeneratedTodayRepository calls the React parity source APIs', () async {
    final requests = <RequestOptions>[];
    final client = generated.MavraApi(basePathOverride: 'https://api.example')
      ..dio.httpClientAdapter = _Adapter((options) {
        requests.add(options);
        return _jsonResponse(200, _responseFor(options.path));
      });
    final repository = GeneratedTodayRepository(
      config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
      client: client,
    );

    final snapshot = await repository.loadToday();

    expect(snapshot.headline, '今天只提醒 3 件事。');
    expect(snapshot.attentionItems.first.title, '米家电饭煲 到了心理价位');

    final productsRequest = requests.singleWhere(
      (request) => request.path == '/api/v1/products',
    );
    expect(productsRequest.queryParameters['active'], isTrue);
    expect(productsRequest.queryParameters['page'], 1);
    expect(productsRequest.queryParameters['size'], 5);

    final matchesRequest = requests.singleWhere(
      (request) => request.path == '/api/v1/jobs/match-results',
    );
    expect(matchesRequest.queryParameters['page'], 1);
    expect(matchesRequest.queryParameters['page_size'], 5);
  });

  test(
    'GeneratedTodayRepository keeps a default brief when one source fails',
    () async {
      final client = generated.MavraApi(basePathOverride: 'https://api.example')
        ..dio.httpClientAdapter = _Adapter((options) {
          if (options.path == '/api/v1/products') {
            return _jsonResponse(500, {'message': 'offline'});
          }
          return _jsonResponse(200, _responseFor(options.path));
        });
      final repository = GeneratedTodayRepository(
        config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
        client: client,
      );

      final snapshot = await repository.loadToday();

      expect(snapshot.warningMessage, '今天的简报没有完全同步，稍后会再试。');
      expect(snapshot.headline, '今天只提醒 3 件事。');
      expect(snapshot.attentionItems.map((item) => item.kind), [
        TodayAttentionKind.price,
        TodayAttentionKind.job,
        TodayAttentionKind.home,
      ]);
      expect(snapshot.attentionItems.first.title, '一个关注商品 到了心理价位');
    },
  );
}

Object _responseFor(String path) {
  return switch (path) {
    '/api/v1/dashboard/kpi' => {
      'user': {
        'total_products': 4,
        'price_drops_today': 1,
        'new_jobs_today': 0,
        'match_count': 1,
        'crawl_count_today': 2,
      },
    },
    '/api/v1/products' => {
      'items': [
        {
          'active': true,
          'created_at': '2026-06-17T08:00:00Z',
          'id': 1,
          'platform': 'taobao',
          'title': '米家电饭煲',
          'updated_at': '2026-06-17T08:00:00Z',
          'url': 'https://example.test/product',
          'user_id': 1,
        },
      ],
      'page': 1,
      'page_size': 5,
      'total': 1,
      'total_pages': 1,
      'has_next': false,
      'has_prev': false,
    },
    '/api/v1/jobs/match-results' => {
      'items': [
        {
          'created_at': '2026-06-17T08:00:00Z',
          'id': 7,
          'job_id': 70,
          'match_score': 92,
          'resume_id': 3,
          'updated_at': '2026-06-17T08:00:00Z',
          'user_id': 1,
          'job_title': 'Flutter 工程师',
          'job_company': 'Mavra Labs',
          'job_location': '上海',
        },
      ],
      'page': 1,
      'page_size': 5,
      'total': 1,
    },
    '/api/v1/smart-home/summary' => {
      'configured': true,
      'connected': false,
      'unavailable_count': 2,
      'active_count': 10,
    },
    _ => throw StateError('Unexpected path $path'),
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
