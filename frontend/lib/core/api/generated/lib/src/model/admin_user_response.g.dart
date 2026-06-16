// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminUserResponse extends AdminUserResponse {
  @override
  final DateTime createdAt;
  @override
  final String email;
  @override
  final int id;
  @override
  final String role;
  @override
  final String username;
  @override
  final bool? isActive;

  factory _$AdminUserResponse(
          [void Function(AdminUserResponseBuilder)? updates]) =>
      (AdminUserResponseBuilder()..update(updates))._build();

  _$AdminUserResponse._(
      {required this.createdAt,
      required this.email,
      required this.id,
      required this.role,
      required this.username,
      this.isActive})
      : super._();
  @override
  AdminUserResponse rebuild(void Function(AdminUserResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AdminUserResponseBuilder toBuilder() =>
      AdminUserResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminUserResponse &&
        createdAt == other.createdAt &&
        email == other.email &&
        id == other.id &&
        role == other.role &&
        username == other.username &&
        isActive == other.isActive;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminUserResponse')
          ..add('createdAt', createdAt)
          ..add('email', email)
          ..add('id', id)
          ..add('role', role)
          ..add('username', username)
          ..add('isActive', isActive))
        .toString();
  }
}

class AdminUserResponseBuilder
    implements Builder<AdminUserResponse, AdminUserResponseBuilder> {
  _$AdminUserResponse? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  AdminUserResponseBuilder() {
    AdminUserResponse._defaults(this);
  }

  AdminUserResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _email = $v.email;
      _id = $v.id;
      _role = $v.role;
      _username = $v.username;
      _isActive = $v.isActive;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminUserResponse other) {
    _$v = other as _$AdminUserResponse;
  }

  @override
  void update(void Function(AdminUserResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminUserResponse build() => _build();

  _$AdminUserResponse _build() {
    final _$result = _$v ??
        _$AdminUserResponse._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'AdminUserResponse', 'createdAt'),
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'AdminUserResponse', 'email'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'AdminUserResponse', 'id'),
          role: BuiltValueNullFieldError.checkNotNull(
              role, r'AdminUserResponse', 'role'),
          username: BuiltValueNullFieldError.checkNotNull(
              username, r'AdminUserResponse', 'username'),
          isActive: isActive,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
