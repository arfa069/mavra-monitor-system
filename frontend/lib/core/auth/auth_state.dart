import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/platform_capabilities.dart';
import 'auth_repository.dart';

final platformCapabilitiesProvider = Provider<PlatformCapabilities>((ref) {
  return PlatformCapabilities.current();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final capabilities = ref.watch(platformCapabilitiesProvider);
  if (capabilities.secureStorageMode == SecureStorageMode.webCookie) {
    return AuthRepository(
      storage: InMemoryTokenStorage(),
      policy: TokenPersistencePolicy.webHttpOnlyRefreshCookie,
    );
  }

  return AuthRepository(
    storage: const SecureTokenStorage(),
    policy: TokenPersistencePolicy.nativeSecureStorage,
  );
});

final authSessionProvider = FutureProvider<AuthSession?>((ref) {
  return ref.watch(authRepositoryProvider).loadSession();
});
