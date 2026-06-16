// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuthSessionResponse extends AuthSessionResponse {
  @override
  final String accessToken;
  @override
  final int expiresIn;
  @override
  final UserResponse user;
  @override
  final String? refreshToken;
  @override
  final String? tokenType;

  factory _$AuthSessionResponse(
          [void Function(AuthSessionResponseBuilder)? updates]) =>
      (AuthSessionResponseBuilder()..update(updates))._build();

  _$AuthSessionResponse._(
      {required this.accessToken,
      required this.expiresIn,
      required this.user,
      this.refreshToken,
      this.tokenType})
      : super._();
  @override
  AuthSessionResponse rebuild(
          void Function(AuthSessionResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuthSessionResponseBuilder toBuilder() =>
      AuthSessionResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuthSessionResponse &&
        accessToken == other.accessToken &&
        expiresIn == other.expiresIn &&
        user == other.user &&
        refreshToken == other.refreshToken &&
        tokenType == other.tokenType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, expiresIn.hashCode);
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, tokenType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuthSessionResponse')
          ..add('accessToken', accessToken)
          ..add('expiresIn', expiresIn)
          ..add('user', user)
          ..add('refreshToken', refreshToken)
          ..add('tokenType', tokenType))
        .toString();
  }
}

class AuthSessionResponseBuilder
    implements Builder<AuthSessionResponse, AuthSessionResponseBuilder> {
  _$AuthSessionResponse? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  int? _expiresIn;
  int? get expiresIn => _$this._expiresIn;
  set expiresIn(int? expiresIn) => _$this._expiresIn = expiresIn;

  UserResponseBuilder? _user;
  UserResponseBuilder get user => _$this._user ??= UserResponseBuilder();
  set user(UserResponseBuilder? user) => _$this._user = user;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  String? _tokenType;
  String? get tokenType => _$this._tokenType;
  set tokenType(String? tokenType) => _$this._tokenType = tokenType;

  AuthSessionResponseBuilder() {
    AuthSessionResponse._defaults(this);
  }

  AuthSessionResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _expiresIn = $v.expiresIn;
      _user = $v.user.toBuilder();
      _refreshToken = $v.refreshToken;
      _tokenType = $v.tokenType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuthSessionResponse other) {
    _$v = other as _$AuthSessionResponse;
  }

  @override
  void update(void Function(AuthSessionResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuthSessionResponse build() => _build();

  _$AuthSessionResponse _build() {
    _$AuthSessionResponse _$result;
    try {
      _$result = _$v ??
          _$AuthSessionResponse._(
            accessToken: BuiltValueNullFieldError.checkNotNull(
                accessToken, r'AuthSessionResponse', 'accessToken'),
            expiresIn: BuiltValueNullFieldError.checkNotNull(
                expiresIn, r'AuthSessionResponse', 'expiresIn'),
            user: user.build(),
            refreshToken: refreshToken,
            tokenType: tokenType,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'user';
        user.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AuthSessionResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
