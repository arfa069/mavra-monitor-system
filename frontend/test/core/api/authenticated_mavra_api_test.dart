import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/api/authenticated_mavra_api.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/core/config/app_config.dart';

void main() {
  test('generated API requests include the current bearer token', () async {
    final repository = AuthRepository(
      storage: InMemoryTokenStorage(),
      policy: TokenPersistencePolicy.nativeSecureStorage,
    );
    await repository.saveSession(_session(accessToken: 'access-token'));

    RequestOptions? captured;
    final client =
        createAuthenticatedMavraApi(
            config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
            authRepository: repository,
          )
          ..dio.httpClientAdapter = _Adapter((options) {
            captured = options;
            return _jsonResponse(200, {'ok': true});
          });

    await client.dio.get('/api/v1/dashboard/kpi');

    expect(client.dio.options.baseUrl, 'https://api.example');
    expect(captured?.headers['Authorization'], 'Bearer access-token');
  });

  test(
    'omits empty optional query parameters before sending requests',
    () async {
      RequestOptions? captured;
      final client =
          createAuthenticatedMavraApi(
              config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
              authRepository: AuthRepository(
                storage: InMemoryTokenStorage(),
                policy: TokenPersistencePolicy.nativeSecureStorage,
              ),
            )
            ..dio.httpClientAdapter = _Adapter((options) {
              captured = options;
              return _jsonResponse(200, {'ok': true});
            });

      await client.dio.get(
        '/api/v1/events',
        queryParameters: {
          'kind': 'all',
          'event_type': '',
          'category': '',
          'start_at': '',
          'end_at': '',
          'page': 1,
          'active': false,
          'limit': 0,
        },
      );

      expect(captured?.queryParameters, {
        'kind': 'all',
        'page': 1,
        'active': false,
        'limit': 0,
      });
    },
  );

  test('enables browser credentials for web cookie auth requests', () async {
    RequestOptions? captured;
    final client =
        createAuthenticatedMavraApi(
            config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
            authRepository: AuthRepository(
              storage: InMemoryTokenStorage(),
              policy: TokenPersistencePolicy.webHttpOnlyRefreshCookie,
            ),
          )
          ..dio.httpClientAdapter = _Adapter((options) {
            captured = options;
            return _jsonResponse(200, {'ok': true});
          });

    await client.dio.post('/api/v1/auth/refresh');

    expect(captured?.extra['withCredentials'], isTrue);
  });

  test(
    'refreshes generated API requests after a 401 and retries once',
    () async {
      final repository = AuthRepository(
        storage: InMemoryTokenStorage(),
        policy: TokenPersistencePolicy.nativeSecureStorage,
        refreshRemote: () async => _session(accessToken: 'fresh-token'),
      );
      await repository.saveSession(_session(accessToken: 'expired-token'));

      final seenTokens = <String?>[];
      var requests = 0;
      final client =
          createAuthenticatedMavraApi(
              config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
              authRepository: repository,
            )
            ..dio.httpClientAdapter = _Adapter((options) {
              requests += 1;
              seenTokens.add(options.headers['Authorization'] as String?);
              if (requests == 1) {
                return _jsonResponse(401, {
                  'code': 'TOKEN_EXPIRED',
                  'message': 'Expired',
                });
              }
              return _jsonResponse(200, {'ok': true});
            });

      final response = await client.dio.get('/api/v1/products');

      expect(response.statusCode, 200);
      expect(requests, 2);
      expect(seenTokens, ['Bearer expired-token', 'Bearer fresh-token']);
    },
  );
}

AuthSession _session({required String accessToken}) {
  return AuthSession(
    accessToken: accessToken,
    refreshToken: 'refresh-token',
    expiresAt: DateTime.utc(2026, 1, 1),
    username: 'demo',
    permissions: const {'user:read'},
  );
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
