// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'we_chat_register_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WeChatRegisterRequest extends WeChatRegisterRequest {
  @override
  final String email;
  @override
  final String password;
  @override
  final String tempToken;
  @override
  final String username;

  factory _$WeChatRegisterRequest([
    void Function(WeChatRegisterRequestBuilder)? updates,
  ]) => (WeChatRegisterRequestBuilder()..update(updates))._build();

  _$WeChatRegisterRequest._({
    required this.email,
    required this.password,
    required this.tempToken,
    required this.username,
  }) : super._();
  @override
  WeChatRegisterRequest rebuild(
    void Function(WeChatRegisterRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WeChatRegisterRequestBuilder toBuilder() =>
      WeChatRegisterRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WeChatRegisterRequest &&
        email == other.email &&
        password == other.password &&
        tempToken == other.tempToken &&
        username == other.username;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, tempToken.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WeChatRegisterRequest')
          ..add('email', email)
          ..add('password', password)
          ..add('tempToken', tempToken)
          ..add('username', username))
        .toString();
  }
}

class WeChatRegisterRequestBuilder
    implements Builder<WeChatRegisterRequest, WeChatRegisterRequestBuilder> {
  _$WeChatRegisterRequest? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _tempToken;
  String? get tempToken => _$this._tempToken;
  set tempToken(String? tempToken) => _$this._tempToken = tempToken;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  WeChatRegisterRequestBuilder() {
    WeChatRegisterRequest._defaults(this);
  }

  WeChatRegisterRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _password = $v.password;
      _tempToken = $v.tempToken;
      _username = $v.username;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WeChatRegisterRequest other) {
    _$v = other as _$WeChatRegisterRequest;
  }

  @override
  void update(void Function(WeChatRegisterRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WeChatRegisterRequest build() => _build();

  _$WeChatRegisterRequest _build() {
    final _$result =
        _$v ??
        _$WeChatRegisterRequest._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'WeChatRegisterRequest',
            'email',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'WeChatRegisterRequest',
            'password',
          ),
          tempToken: BuiltValueNullFieldError.checkNotNull(
            tempToken,
            r'WeChatRegisterRequest',
            'tempToken',
          ),
          username: BuiltValueNullFieldError.checkNotNull(
            username,
            r'WeChatRegisterRequest',
            'username',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
