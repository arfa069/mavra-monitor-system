// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_log_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LoginLogResponse extends LoginLogResponse {
  @override
  final DateTime createdAt;
  @override
  final int id;
  @override
  final String? ipAddress;
  @override
  final String? userAgent;

  factory _$LoginLogResponse(
          [void Function(LoginLogResponseBuilder)? updates]) =>
      (LoginLogResponseBuilder()..update(updates))._build();

  _$LoginLogResponse._(
      {required this.createdAt,
      required this.id,
      this.ipAddress,
      this.userAgent})
      : super._();
  @override
  LoginLogResponse rebuild(void Function(LoginLogResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LoginLogResponseBuilder toBuilder() =>
      LoginLogResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LoginLogResponse &&
        createdAt == other.createdAt &&
        id == other.id &&
        ipAddress == other.ipAddress &&
        userAgent == other.userAgent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, ipAddress.hashCode);
    _$hash = $jc(_$hash, userAgent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LoginLogResponse')
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('ipAddress', ipAddress)
          ..add('userAgent', userAgent))
        .toString();
  }
}

class LoginLogResponseBuilder
    implements Builder<LoginLogResponse, LoginLogResponseBuilder> {
  _$LoginLogResponse? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _ipAddress;
  String? get ipAddress => _$this._ipAddress;
  set ipAddress(String? ipAddress) => _$this._ipAddress = ipAddress;

  String? _userAgent;
  String? get userAgent => _$this._userAgent;
  set userAgent(String? userAgent) => _$this._userAgent = userAgent;

  LoginLogResponseBuilder() {
    LoginLogResponse._defaults(this);
  }

  LoginLogResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _id = $v.id;
      _ipAddress = $v.ipAddress;
      _userAgent = $v.userAgent;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LoginLogResponse other) {
    _$v = other as _$LoginLogResponse;
  }

  @override
  void update(void Function(LoginLogResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LoginLogResponse build() => _build();

  _$LoginLogResponse _build() {
    final _$result = _$v ??
        _$LoginLogResponse._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'LoginLogResponse', 'createdAt'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'LoginLogResponse', 'id'),
          ipAddress: ipAddress,
          userAgent: userAgent,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
