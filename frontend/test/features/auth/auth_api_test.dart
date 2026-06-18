import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_api/mavra_api.dart' as generated;
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/features/auth/data/auth_api.dart';

void main() {
  test('refreshGeneratedAuthSession maps generated refresh responses', () async {
    final repository = AuthRepository(
      storage: InMemoryTokenStorage(),
      policy: TokenPersistencePolicy.nativeSecureStorage,
    );
    await repository.saveSession(_session());

    RequestOptions? captured;
    String? requestBody;
    final client = generated.MavraApi(basePathOverride: 'https://api.example')
      ..dio.httpClientAdapter = _Adapter((options, body) {
        captured = options;
        requestBody = body;
        return _jsonResponse(200, {
          'access_token': 'fresh-access',
          'refresh_token': 'fresh-refresh',
          'expires_in': 900,
          'user': {
            'id': 1,
            'username': 'mavra',
            'email': 'mavra@example.com',
            'created_at': '2026-06-16T00:00:00Z',
            'permissions': ['user:read', 'config:read'],
            'role': 'admin',
          },
        });
      });

    final refreshed = await refreshGeneratedAuthSession(
      client: client,
      repository: repository,
    );

    expect(captured?.path, '/api/v1/auth/refresh');
    expect(requestBody, contains('refresh-token'));
    expect(refreshed?.accessToken, 'fresh-access');
    expect(refreshed?.refreshToken, 'fresh-refresh');
    expect(refreshed?.username, 'mavra');
    expect(refreshed?.permissions, {'user:read', 'config:read'});
  });
}

AuthSession _session() {
  return AuthSession(
    accessToken: 'expired-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.utc(2026, 6, 16),
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

  final FutureOr<ResponseBody> Function(RequestOptions options, String body)
  handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = requestStream == null
        ? ''
        : utf8.decode(await requestStream.expand((chunk) => chunk).toList());
    return handler(options, body);
  }

  @override
  void close({bool force = false}) {}
}
