import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/core/auth/auth_state.dart';
import 'package:mavra_frontend/core/platform/platform_capabilities.dart';

void main() {
  group('authRepositoryProvider', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('uses secure token storage for native platforms', () {
      final container = ProviderContainer(
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(
            PlatformCapabilities.forEnvironment(
              isWeb: false,
              platform: TargetPlatform.windows,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(authRepositoryProvider);

      expect(repository.policy, TokenPersistencePolicy.nativeSecureStorage);
      expect(repository.storage, isA<SecureTokenStorage>());
    });

    test('uses cookie policy for web refresh tokens', () {
      final container = ProviderContainer(
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(
            PlatformCapabilities.forEnvironment(
              isWeb: true,
              platform: TargetPlatform.windows,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(authRepositoryProvider);

      expect(
        repository.policy,
        TokenPersistencePolicy.webHttpOnlyRefreshCookie,
      );
      expect(repository.storage, isA<InMemoryTokenStorage>());
    });
  });
}
