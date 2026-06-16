// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminUserUpdate extends AdminUserUpdate {
  @override
  final String? email;
  @override
  final bool? isActive;
  @override
  final String? role;
  @override
  final String? username;

  factory _$AdminUserUpdate([void Function(AdminUserUpdateBuilder)? updates]) =>
      (AdminUserUpdateBuilder()..update(updates))._build();

  _$AdminUserUpdate._({this.email, this.isActive, this.role, this.username})
    : super._();
  @override
  AdminUserUpdate rebuild(void Function(AdminUserUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AdminUserUpdateBuilder toBuilder() => AdminUserUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminUserUpdate &&
        email == other.email &&
        isActive == other.isActive &&
        role == other.role &&
        username == other.username;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminUserUpdate')
          ..add('email', email)
          ..add('isActive', isActive)
          ..add('role', role)
          ..add('username', username))
        .toString();
  }
}

class AdminUserUpdateBuilder
    implements Builder<AdminUserUpdate, AdminUserUpdateBuilder> {
  _$AdminUserUpdate? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  AdminUserUpdateBuilder() {
    AdminUserUpdate._defaults(this);
  }

  AdminUserUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _isActive = $v.isActive;
      _role = $v.role;
      _username = $v.username;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminUserUpdate other) {
    _$v = other as _$AdminUserUpdate;
  }

  @override
  void update(void Function(AdminUserUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminUserUpdate build() => _build();

  _$AdminUserUpdate _build() {
    final _$result =
        _$v ??
        _$AdminUserUpdate._(
          email: email,
          isActive: isActive,
          role: role,
          username: username,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
