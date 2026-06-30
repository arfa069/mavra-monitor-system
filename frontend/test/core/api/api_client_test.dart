import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/api/api_client.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/core/config/app_config.dart';
import 'package:mavra_frontend/core/errors/api_error.dart';
import 'package:mavra_frontend/core/widgets/async_state_view.dart';

void main() {
  group('MavraApiClient', () {
    test('attaches access token as a Bearer header', () async {
      final store = InMemoryTokenStorage();
      final repository = AuthRepository(
        storage: store,
        policy: TokenPersistencePolicy.nativeSecureStorage,
      );
      await repository.saveSession(_session(accessToken: 'access-token'));

      RequestOptions? captured;
      final client =
          MavraApiClient(
              config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
              authRepository: repository,
            )
            ..dio.httpClientAdapter = _Adapter((options) {
              captured = options;
              return _jsonResponse(200, {'ok': true});
            });

      await client.dio.get('/products');

      expect(captured?.headers['Authorization'], 'Bearer access-token');
    });

    test('refreshes once after a 401 and retries with the new token', () async {
      final repository = AuthRepository(
        storage: InMemoryTokenStorage(),
        policy: TokenPersistencePolicy.nativeSecureStorage,
        refreshRemote: () async => _session(accessToken: 'fresh-token'),
      );
      await repository.saveSession(_session(accessToken: 'expired-token'));

      final seenTokens = <String?>[];
      var requests = 0;
      final client =
          MavraApiClient(
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

      final response = await client.dio.get('/products');

      expect(response.statusCode, 200);
      expect(requests, 2);
      expect(seenTokens, ['Bearer expired-token', 'Bearer fresh-token']);
    });

    test('clears session when refresh is rejected', () async {
      final repository = AuthRepository(
        storage: InMemoryTokenStorage(),
        policy: TokenPersistencePolicy.nativeSecureStorage,
        refreshRemote: () async => null,
      );
      await repository.saveSession(_session(accessToken: 'expired-token'));

      final client =
          MavraApiClient(
              config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
              authRepository: repository,
            )
            ..dio.httpClientAdapter = _Adapter(
              (_) => _jsonResponse(401, {
                'code': 'TOKEN_EXPIRED',
                'message': 'Expired',
              }),
            );

      await expectLater(
        client.dio.get('/products'),
        throwsA(isA<DioException>()),
      );
      expect(repository.currentSession, isNull);
    });

    test('keeps the current session when refresh fails transiently', () async {
      final repository = AuthRepository(
        storage: InMemoryTokenStorage(),
        policy: TokenPersistencePolicy.nativeSecureStorage,
        refreshRemote: () async => throw StateError('network down'),
      );
      await repository.saveSession(_session(accessToken: 'expired-token'));

      final client =
          MavraApiClient(
              config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
              authRepository: repository,
            )
            ..dio.httpClientAdapter = _Adapter(
              (_) => _jsonResponse(401, {
                'code': 'TOKEN_EXPIRED',
                'message': 'Expired',
              }),
            );

      await expectLater(
        client.dio.get('/products'),
        throwsA(isA<DioException>()),
      );
      expect(repository.currentSession?.accessToken, 'expired-token');
    });
  });

  group('ApiError', () {
    test('maps backend error envelopes to typed errors', () {
      final error = ApiError.fromResponse(
        Response<dynamic>(
          requestOptions: RequestOptions(path: '/products'),
          statusCode: 500,
          data: {
            'code': 'INTERNAL_ERROR',
            'message': 'Something failed',
            'details': {'field': 'value'},
            'trace_id': 'trace-123',
            'help_url': 'https://docs.example/errors/internal',
          },
        ),
      );

      expect(error.code, 'INTERNAL_ERROR');
      expect(error.message, 'Something failed');
      expect(error.details, {'field': 'value'});
      expect(error.traceId, 'trace-123');
      expect(error.helpUrl, 'https://docs.example/errors/internal');
    });

    testWidgets('renders problem, cause, action, and trace id', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApiErrorPanel(
              error: const ApiError(
                code: 'AUTH_REQUIRED',
                message: 'Please sign in again',
                details: {'reason': 'session expired'},
                traceId: 'trace-401',
                helpUrl: 'https://docs.example/errors/auth',
              ),
              likelyCause: 'Your session expired.',
              nextAction: 'Log in again.',
            ),
          ),
        ),
      );

      expect(find.text('Please sign in again'), findsOneWidget);
      expect(find.text('Your session expired.'), findsOneWidget);
      expect(find.text('Log in again.'), findsOneWidget);
      expect(find.textContaining('trace-401'), findsOneWidget);
    });
  });
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
