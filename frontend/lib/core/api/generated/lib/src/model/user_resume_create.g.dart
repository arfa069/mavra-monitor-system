// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_resume_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserResumeCreate extends UserResumeCreate {
  @override
  final String name;
  @override
  final String resumeText;

  factory _$UserResumeCreate([
    void Function(UserResumeCreateBuilder)? updates,
  ]) => (UserResumeCreateBuilder()..update(updates))._build();

  _$UserResumeCreate._({required this.name, required this.resumeText})
    : super._();
  @override
  UserResumeCreate rebuild(void Function(UserResumeCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserResumeCreateBuilder toBuilder() =>
      UserResumeCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserResumeCreate &&
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
    return (newBuiltValueToStringHelper(r'UserResumeCreate')
          ..add('name', name)
          ..add('resumeText', resumeText))
        .toString();
  }
}

class UserResumeCreateBuilder
    implements Builder<UserResumeCreate, UserResumeCreateBuilder> {
  _$UserResumeCreate? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _resumeText;
  String? get resumeText => _$this._resumeText;
  set resumeText(String? resumeText) => _$this._resumeText = resumeText;

  UserResumeCreateBuilder() {
    UserResumeCreate._defaults(this);
  }

  UserResumeCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _resumeText = $v.resumeText;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserResumeCreate other) {
    _$v = other as _$UserResumeCreate;
  }

  @override
  void update(void Function(UserResumeCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserResumeCreate build() => _build();

  _$UserResumeCreate _build() {
    final _$result =
        _$v ??
        _$UserResumeCreate._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'UserResumeCreate',
            'name',
          ),
          resumeText: BuiltValueNullFieldError.checkNotNull(
            resumeText,
            r'UserResumeCreate',
            'resumeText',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
