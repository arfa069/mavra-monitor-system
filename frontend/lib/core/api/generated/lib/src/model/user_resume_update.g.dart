// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_resume_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserResumeUpdate extends UserResumeUpdate {
  @override
  final String? name;
  @override
  final String? resumeText;

  factory _$UserResumeUpdate([
    void Function(UserResumeUpdateBuilder)? updates,
  ]) => (UserResumeUpdateBuilder()..update(updates))._build();

  _$UserResumeUpdate._({this.name, this.resumeText}) : super._();
  @override
  UserResumeUpdate rebuild(void Function(UserResumeUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserResumeUpdateBuilder toBuilder() =>
      UserResumeUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserResumeUpdate &&
        name == other.name &&
        resumeText == other.resumeText;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, resumeText.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserResumeUpdate')
          ..add('name', name)
          ..add('resumeText', resumeText))
        .toString();
  }
}

class UserResumeUpdateBuilder
    implements Builder<UserResumeUpdate, UserResumeUpdateBuilder> {
  _$UserResumeUpdate? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _resumeText;
  String? get resumeText => _$this._resumeText;
  set resumeText(String? resumeText) => _$this._resumeText = resumeText;

  UserResumeUpdateBuilder() {
    UserResumeUpdate._defaults(this);
  }

  UserResumeUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _resumeText = $v.resumeText;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserResumeUpdate other) {
    _$v = other as _$UserResumeUpdate;
  }

  @override
  void update(void Function(UserResumeUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserResumeUpdate build() => _build();

  _$UserResumeUpdate _build() {
    final _$result =
        _$v ?? _$UserResumeUpdate._(name: name, resumeText: resumeText);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
