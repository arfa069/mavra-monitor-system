import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum TokenPersistencePolicy { nativeSecureStorage, webHttpOnlyRefreshCookie }

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.username,
    required this.permissions,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String username;
  final Set<String> permissions;

  bool hasPermission(String permission) => permissions.contains(permission);
}

abstract class TokenStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage([
    this._secureStorage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> read(String key) {
    return _secureStorage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) {
    return _secureStorage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) {
    return _secureStorage.delete(key: key);
  }
}

typedef RefreshRemote = Future<AuthSession?> Function();
typedef RemoteLogout = Future<void> Function();
typedef LocalSessionCleared = void Function();

class AuthRepository {
  AuthRepository({
    required this.storage,
    required this.policy,
    this.refreshRemote,
    this.onRemoteLogout,
    this.onLocalSessionCleared,
  });

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const accessExpiresAtKey = 'access_expires_at';
  static const usernameKey = 'username';
  static const permissionsKey = 'permissions';

  final TokenStorage storage;
  final TokenPersistencePolicy policy;
  final RefreshRemote? refreshRemote;
  final RemoteLogout? onRemoteLogout;
  LocalSessionCleared? onLocalSessionCleared;

  AuthSession? _currentSession;

  AuthSession? get currentSession => _currentSession;

  Future<String?> getAccessToken() async {
    final current = _currentSession;
    if (current != null) {
      return current.accessToken;
    }
    final loaded = await loadSession();
    return loaded?.accessToken;
  }

  Future<void> saveSession(AuthSession session) async {
    _currentSession = session;
    if (policy == TokenPersistencePolicy.webHttpOnlyRefreshCookie) {
      return;
    }

    await storage.write(accessTokenKey, session.accessToken);
    await storage.write(refreshTokenKey, session.refreshToken);
    await storage.write(
      accessExpiresAtKey,
      session.expiresAt.toIso8601String(),
    );
    await storage.write(usernameKey, session.username);
    await storage.write(permissionsKey, session.permissions.join(','));
  }

  Future<AuthSession?> loadSession() async {
    if (_currentSession != null) {
      return _currentSession;
    }
    if (policy == TokenPersistencePolicy.webHttpOnlyRefreshCookie) {
      return null;
    }

    final accessToken = await storage.read(accessTokenKey);
    final refreshToken = await storage.read(refreshTokenKey);
    final expiresAtRaw = await storage.read(accessExpiresAtKey);
    final username = await storage.read(usernameKey);
    if (accessToken == null ||
        refreshToken == null ||
        expiresAtRaw == null ||
        username == null) {
      return null;
    }

    final permissionsRaw = await storage.read(permissionsKey);
    final permissions = permissionsRaw == null || permissionsRaw.isEmpty
        ? <String>{}
        : permissionsRaw.split(',').toSet();

    _currentSession = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiresAtRaw),
      username: username,
      permissions: permissions,
    );
    return _currentSession;
  }

  Future<bool> refreshSession() async {
    AuthSession? refreshed;
    try {
      refreshed = await refreshRemote?.call();
    } catch (_) {
      await clearLocalSession();
      return false;
    }
    if (refreshed == null) {
      await clearLocalSession();
      return false;
    }
    await saveSession(refreshed);
    return true;
  }

  Future<void> clearLocalSession() async {
    _currentSession = null;
    await storage.delete(accessTokenKey);
    await storage.delete(refreshTokenKey);
    await storage.delete(accessExpiresAtKey);
    await storage.delete(usernameKey);
    await storage.delete(permissionsKey);
    onLocalSessionCleared?.call();
  }

  Future<void> logout() async {
    await clearLocalSession();
    await onRemoteLogout?.call();
  }
}
