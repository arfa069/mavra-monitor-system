// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_change.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PasswordChange extends PasswordChange {
  @override
  final String newPassword;
  @override
  final String oldPassword;
  @override
  final String? refreshToken;

  factory _$PasswordChange([void Function(PasswordChangeBuilder)? updates]) =>
      (PasswordChangeBuilder()..update(updates))._build();

  _$PasswordChange._({
    required this.newPassword,
    required this.oldPassword,
    this.refreshToken,
  }) : super._();
  @override
  PasswordChange rebuild(void Function(PasswordChangeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PasswordChangeBuilder toBuilder() => PasswordChangeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PasswordChange &&
        newPassword == other.newPassword &&
        oldPassword == other.oldPassword &&
        refreshToken == other.refreshToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, newPassword.hashCode);
    _$hash = $jc(_$hash, oldPassword.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PasswordChange')
          ..add('newPassword', newPassword)
          ..add('oldPassword', oldPassword)
          ..add('refreshToken', refreshToken))
        .toString();
  }
}

class PasswordChangeBuilder
    implements Builder<PasswordChange, PasswordChangeBuilder> {
  _$PasswordChange? _$v;

  String? _newPassword;
  String? get newPassword => _$this._newPassword;
  set newPassword(String? newPassword) => _$this._newPassword = newPassword;

  String? _oldPassword;
  String? get oldPassword => _$this._oldPassword;
  set oldPassword(String? oldPassword) => _$this._oldPassword = oldPassword;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  PasswordChangeBuilder() {
    PasswordChange._defaults(this);
  }

  PasswordChangeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _newPassword = $v.newPassword;
      _oldPassword = $v.oldPassword;
      _refreshToken = $v.refreshToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PasswordChange other) {
    _$v = other as _$PasswordChange;
  }

  @override
  void update(void Function(PasswordChangeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PasswordChange build() => _build();

  _$PasswordChange _build() {
    final _$result =
        _$v ??
        _$PasswordChange._(
          newPassword: BuiltValueNullFieldError.checkNotNull(
            newPassword,
            r'PasswordChange',
            'newPassword',
          ),
          oldPassword: BuiltValueNullFieldError.checkNotNull(
            oldPassword,
            r'PasswordChange',
            'oldPassword',
          ),
          refreshToken: refreshToken,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
