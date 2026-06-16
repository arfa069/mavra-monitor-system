import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    storage: InMemoryTokenStorage(),
    policy: TokenPersistencePolicy.nativeSecureStorage,
  );
});

final authSessionProvider = FutureProvider<AuthSession?>((ref) {
  return ref.watch(authRepositoryProvider).loadSession();
});
