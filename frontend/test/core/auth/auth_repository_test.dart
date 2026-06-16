import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    test(
      'persists access and refresh tokens for native secure storage',
      () async {
        final storage = InMemoryTokenStorage();
        final repository = AuthRepository(
          storage: storage,
          policy: TokenPersistencePolicy.nativeSecureStorage,
        );

        await repository.saveSession(_session());

        expect(
          await storage.read(AuthRepository.accessTokenKey),
          'access-token',
        );
        expect(
          await storage.read(AuthRepository.refreshTokenKey),
          'refresh-token',
        );

        final reloaded = AuthRepository(
          storage: storage,
          policy: TokenPersistencePolicy.nativeSecureStorage,
        );
        final loadedSession = await reloaded.loadSession();

        expect(loadedSession?.accessToken, 'access-token');
        expect(loadedSession?.refreshToken, 'refresh-token');
      },
    );

    test(
      'keeps web access token in memory and avoids readable refresh storage',
      () async {
        final storage = InMemoryTokenStorage();
        final repository = AuthRepository(
          storage: storage,
          policy: TokenPersistencePolicy.webHttpOnlyRefreshCookie,
        );

        await repository.saveSession(_session());

        expect(repository.currentSession?.accessToken, 'access-token');
        expect(await storage.read(AuthRepository.accessTokenKey), isNull);
        expect(await storage.read(AuthRepository.refreshTokenKey), isNull);

        final reloaded = AuthRepository(
          storage: storage,
          policy: TokenPersistencePolicy.webHttpOnlyRefreshCookie,
        );

        expect(await reloaded.loadSession(), isNull);
      },
    );

    test('logout clears local session and calls backend logout hook', () async {
      var remoteLogoutCalls = 0;
      final storage = InMemoryTokenStorage();
      final repository = AuthRepository(
        storage: storage,
        policy: TokenPersistencePolicy.nativeSecureStorage,
        onRemoteLogout: () async => remoteLogoutCalls += 1,
      );
      await repository.saveSession(_session());

      await repository.logout();

      expect(repository.currentSession, isNull);
      expect(await storage.read(AuthRepository.accessTokenKey), isNull);
      expect(await storage.read(AuthRepository.refreshTokenKey), isNull);
      expect(remoteLogoutCalls, 1);
    });
  });
}

AuthSession _session() {
  return AuthSession(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.utc(2026, 1, 1),
    username: 'demo',
    permissions: const {'user:read', 'blog:read_admin'},
  );
}
