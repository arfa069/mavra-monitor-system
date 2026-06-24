// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_register.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserRegister extends UserRegister {
  @override
  final String email;
  @override
  final String password;
  @override
  final String username;

  factory _$UserRegister([void Function(UserRegisterBuilder)? updates]) =>
      (UserRegisterBuilder()..update(updates))._build();

  _$UserRegister._({
    required this.email,
    required this.password,
    required this.username,
  }) : super._();
  @override
  UserRegister rebuild(void Function(UserRegisterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserRegisterBuilder toBuilder() => UserRegisterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserRegister &&
        email == other.email &&
        password == other.password &&
        username == other.username;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserRegister')
          ..add('email', email)
          ..add('password', password)
          ..add('username', username))
        .toString();
  }
}

class UserRegisterBuilder
    implements Builder<UserRegister, UserRegisterBuilder> {
  _$UserRegister? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  UserRegisterBuilder() {
    UserRegister._defaults(this);
  }

  UserRegisterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _password = $v.password;
      _username = $v.username;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserRegister other) {
    _$v = other as _$UserRegister;
  }

  @override
  void update(void Function(UserRegisterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserRegister build() => _build();

  _$UserRegister _build() {
    final _$result =
        _$v ??
        _$UserRegister._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'UserRegister',
            'email',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'UserRegister',
            'password',
          ),
          username: BuiltValueNullFieldError.checkNotNull(
            username,
            r'UserRegister',
            'username',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
