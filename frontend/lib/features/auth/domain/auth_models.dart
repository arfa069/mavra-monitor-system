import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_repository.dart';

class LoginCredentials {
  const LoginCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

class RegisterAccountInput {
  const RegisterAccountInput({
    required this.username,
    required this.email,
    required this.password,
  });

  final String username;
  final String email;
  final String password;
}

class AccountProfile {
  const AccountProfile({
    required this.username,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final String username;
  final String email;
  final String? role;
  final Set<String> permissions;
}

class AccountProfileDraft {
  const AccountProfileDraft({required this.username, required this.email});

  final String username;
  final String email;
}

class PasswordChangeDraft {
  const PasswordChangeDraft({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class AccountSession {
  const AccountSession({
    required this.id,
    required this.device,
    required this.ipAddress,
    required this.createdAt,
    required this.lastActiveAt,
  });

  final int id;
  final String? device;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime lastActiveAt;
}

class LoginHistoryEntry {
  const LoginHistoryEntry({
    required this.id,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
  });

  final int id;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
}

class AccountOverview {
  const AccountOverview({
    required this.profile,
    required this.sessions,
    required this.loginHistory,
  });

  final AccountProfile profile;
  final List<AccountSession> sessions;
  final List<LoginHistoryEntry> loginHistory;
}

class WeChatExchangeResult {
  const WeChatExchangeResult._({
    required this.status,
    this.session,
    this.tempToken,
    this.nextPath,
  });

  factory WeChatExchangeResult.bound(AuthSession session) {
    return WeChatExchangeResult._(status: 'bound', session: session);
  }

  factory WeChatExchangeResult.unbound({
    required String tempToken,
    String? nextPath,
  }) {
    return WeChatExchangeResult._(
      status: 'unbound',
      tempToken: tempToken,
      nextPath: nextPath,
    );
  }

  factory WeChatExchangeResult.unhandled(String status) {
    return WeChatExchangeResult._(status: status);
  }

  final String status;
  final AuthSession? session;
  final String? tempToken;
  final String? nextPath;

  bool get isBound => session != null;
  bool get isUnbound => tempToken != null;
}

abstract class AuthApiClient {
  Future<AuthSession> login(LoginCredentials credentials);

  Future<void> register(RegisterAccountInput input);

  Future<AccountProfile> fetchProfile();

  Future<List<AccountSession>> listSessions();

  Future<List<LoginHistoryEntry>> listLoginHistory();

  Future<AccountProfile> updateProfile(AccountProfileDraft draft);

  Future<AuthSession> changePassword(PasswordChangeDraft draft);

  Future<WeChatExchangeResult> exchangeWeChatCode(String code);

  Future<void> logout();
}

class AuthController extends ChangeNotifier {
  AuthController({
    required this.api,
    AuthSession? initialSession,
    this.repository,
  }) : _session = initialSession;

  final AuthApiClient api;
  final AuthRepository? repository;

  AuthSession? _session;
  bool _isLoading = false;
  String? _errorMessage;
  WeChatExchangeResult? _lastWeChatExchange;

  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WeChatExchangeResult? get lastWeChatExchange => _lastWeChatExchange;

  bool hasPermission(String permission) {
    return _session?.hasPermission(permission) ?? false;
  }

  Future<void> restoreSession() async {
    final storedSession = await repository?.loadSession();
    if (storedSession == null) {
      return;
    }
    _session = storedSession;
    notifyListeners();
  }

  Future<void> login(LoginCredentials credentials) async {
    await _run(() async {
      _session = await api.login(credentials);
      final session = _session;
      if (session != null) {
        await repository?.saveSession(session);
      }
    });
  }

  Future<void> register(RegisterAccountInput input) async {
    await _run(() => api.register(input));
  }

  Future<void> logout() async {
    await _run(() async {
      await api.logout();
      _session = null;
      await repository?.logout();
    });
  }

  Future<WeChatExchangeResult> exchangeWeChatCode(String code) async {
    late final WeChatExchangeResult result;
    await _run(() async {
      result = await api.exchangeWeChatCode(code);
      _lastWeChatExchange = result;
      final exchangedSession = result.session;
      if (exchangedSession != null) {
        _session = exchangedSession;
        await repository?.saveSession(exchangedSession);
      }
    });
    return result;
  }

  Future<AccountOverview> loadAccountOverview() async {
    final profile = await api.fetchProfile();
    final sessions = await api.listSessions();
    final loginHistory = await api.listLoginHistory();
    return AccountOverview(
      profile: profile,
      sessions: sessions,
      loginHistory: loginHistory,
    );
  }

  Future<AccountProfile> updateProfile(AccountProfileDraft draft) async {
    return api.updateProfile(draft);
  }

  Future<void> changePassword(PasswordChangeDraft draft) async {
    await _run(() async {
      _session = await api.changePassword(draft);
      final session = _session;
      if (session != null) {
        await repository?.saveSession(session);
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
