// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_login_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TokenLoginRequest extends TokenLoginRequest {
  @override
  final String password;
  @override
  final String username;
  @override
  final LoginClientKind? clientKind;

  factory _$TokenLoginRequest([
    void Function(TokenLoginRequestBuilder)? updates,
  ]) => (TokenLoginRequestBuilder()..update(updates))._build();

  _$TokenLoginRequest._({
    required this.password,
    required this.username,
    this.clientKind,
  }) : super._();
  @override
  TokenLoginRequest rebuild(void Function(TokenLoginRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenLoginRequestBuilder toBuilder() =>
      TokenLoginRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenLoginRequest &&
        password == other.password &&
        username == other.username &&
        clientKind == other.clientKind;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jc(_$hash, clientKind.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TokenLoginRequest')
          ..add('password', password)
          ..add('username', username)
          ..add('clientKind', clientKind))
        .toString();
  }
}

class TokenLoginRequestBuilder
    implements Builder<TokenLoginRequest, TokenLoginRequestBuilder> {
  _$TokenLoginRequest? _$v;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  LoginClientKind? _clientKind;
  LoginClientKind? get clientKind => _$this._clientKind;
  set clientKind(LoginClientKind? clientKind) =>
      _$this._clientKind = clientKind;

  TokenLoginRequestBuilder() {
    TokenLoginRequest._defaults(this);
  }

  TokenLoginRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _password = $v.password;
      _username = $v.username;
      _clientKind = $v.clientKind;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TokenLoginRequest other) {
    _$v = other as _$TokenLoginRequest;
  }

  @override
  void update(void Function(TokenLoginRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TokenLoginRequest build() => _build();

  _$TokenLoginRequest _build() {
    final _$result =
        _$v ??
        _$TokenLoginRequest._(
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'TokenLoginRequest',
            'password',
          ),
          username: BuiltValueNullFieldError.checkNotNull(
            username,
            r'TokenLoginRequest',
            'username',
          ),
          clientKind: clientKind,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
