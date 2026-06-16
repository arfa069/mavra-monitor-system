// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'we_chat_bind_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WeChatBindRequest extends WeChatBindRequest {
  @override
  final String password;
  @override
  final String tempToken;
  @override
  final String username;

  factory _$WeChatBindRequest(
          [void Function(WeChatBindRequestBuilder)? updates]) =>
      (WeChatBindRequestBuilder()..update(updates))._build();

  _$WeChatBindRequest._(
      {required this.password, required this.tempToken, required this.username})
      : super._();
  @override
  WeChatBindRequest rebuild(void Function(WeChatBindRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WeChatBindRequestBuilder toBuilder() =>
      WeChatBindRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WeChatBindRequest &&
        password == other.password &&
        tempToken == other.tempToken &&
        username == other.username;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, tempToken.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WeChatBindRequest')
          ..add('password', password)
          ..add('tempToken', tempToken)
          ..add('username', username))
        .toString();
  }
}

class WeChatBindRequestBuilder
    implements Builder<WeChatBindRequest, WeChatBindRequestBuilder> {
  _$WeChatBindRequest? _$v;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _tempToken;
  String? get tempToken => _$this._tempToken;
  set tempToken(String? tempToken) => _$this._tempToken = tempToken;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  WeChatBindRequestBuilder() {
    WeChatBindRequest._defaults(this);
  }

  WeChatBindRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _password = $v.password;
      _tempToken = $v.tempToken;
      _username = $v.username;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WeChatBindRequest other) {
    _$v = other as _$WeChatBindRequest;
  }

  @override
  void update(void Function(WeChatBindRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WeChatBindRequest build() => _build();

  _$WeChatBindRequest _build() {
    final _$result = _$v ??
        _$WeChatBindRequest._(
          password: BuiltValueNullFieldError.checkNotNull(
              password, r'WeChatBindRequest', 'password'),
          tempToken: BuiltValueNullFieldError.checkNotNull(
              tempToken, r'WeChatBindRequest', 'tempToken'),
          username: BuiltValueNullFieldError.checkNotNull(
              username, r'WeChatBindRequest', 'username'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
