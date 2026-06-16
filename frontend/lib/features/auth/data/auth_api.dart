import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../domain/auth_models.dart';

class GeneratedAuthApiClient implements AuthApiClient {
  GeneratedAuthApiClient({
    required AppConfig config,
    generated.MavraApi? client,
    PlatformCapabilities? capabilities,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           ),
       _clientKind = (capabilities ?? PlatformCapabilities.current()).isWeb
           ? generated.LoginClientKind.web
           : generated.LoginClientKind.native_;

  final generated.MavraApi _client;
  final generated.LoginClientKind _clientKind;

  generated.AuthApi get _authApi => _client.getAuthApi();
  generated.WechatApi get _wechatApi => _client.getWechatApi();

  @override
  Future<AuthSession> login(LoginCredentials credentials) async {
    final response = await _authApi.authLogin(
      tokenLoginRequest: generated.TokenLoginRequest(
        (builder) => builder
          ..username = credentials.username
          ..password = credentials.password
          ..clientKind = _clientKind,
      ),
    );
    return _requireSession(response.data);
  }

  @override
  Future<void> register(RegisterAccountInput input) async {
    await _authApi.authRegister(
      userRegister: generated.UserRegister(
        (builder) => builder
          ..username = input.username
          ..email = input.email
          ..password = input.password,
      ),
    );
  }

  @override
  Future<AccountProfile> fetchProfile() async {
    final response = await _authApi.authGetMe();
    final profile = response.data;
    if (profile == null) {
      throw StateError('Auth profile response was empty.');
    }
    return _mapProfile(profile);
  }

  @override
  Future<List<AccountSession>> listSessions() async {
    final response = await _authApi.authListMySessions();
    return [
      for (final session in response.data ?? <generated.SessionResponse>[])
        AccountSession(
          id: session.id,
          device: session.device,
          ipAddress: session.ipAddress,
          createdAt: session.createdAt,
          lastActiveAt: session.lastActiveAt,
        ),
    ];
  }

  @override
  Future<List<LoginHistoryEntry>> listLoginHistory() async {
    final response = await _authApi.authGetMyLoginHistory();
    return [
      for (final entry in response.data ?? <generated.LoginLogResponse>[])
        LoginHistoryEntry(
          id: entry.id,
          ipAddress: entry.ipAddress,
          userAgent: entry.userAgent,
          createdAt: entry.createdAt,
        ),
    ];
  }

  @override
  Future<WeChatExchangeResult> exchangeWeChatCode(String code) async {
    final response = await _wechatApi.wechatExchangeWechatCode(
      weChatExchangeRequest: generated.WeChatExchangeRequest(
        (builder) => builder
          ..exchangeCode = code
          ..clientKind = _clientKind,
      ),
    );
    final result = response.data;
    if (result == null) {
      throw StateError('WeChat exchange response was empty.');
    }
    final session = result.session;
    if (session != null) {
      return WeChatExchangeResult.bound(_mapSession(session));
    }
    final unbound = result.unbound;
    if (unbound != null) {
      return WeChatExchangeResult.unbound(
        tempToken: unbound.tempToken,
        nextPath: unbound.nextPath,
      );
    }
    return WeChatExchangeResult.unhandled(result.status);
  }

  @override
  Future<void> logout() async {
    await _authApi.authLogout();
  }

  AuthSession _requireSession(generated.AuthSessionResponse? response) {
    if (response == null) {
      throw StateError('Auth session response was empty.');
    }
    return _mapSession(response);
  }

  AuthSession _mapSession(generated.AuthSessionResponse response) {
    return AuthSession(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken ?? '',
      expiresAt: DateTime.now().toUtc().add(
        Duration(seconds: response.expiresIn),
      ),
      username: response.user.username,
      permissions: response.user.permissions?.toSet() ?? <String>{},
    );
  }

  AccountProfile _mapProfile(generated.UserResponse response) {
    return AccountProfile(
      username: response.username,
      email: response.email,
      role: response.role,
      permissions: response.permissions?.toSet() ?? <String>{},
    );
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
