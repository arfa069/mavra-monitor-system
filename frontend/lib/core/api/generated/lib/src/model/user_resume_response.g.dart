// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_resume_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserResumeResponse extends UserResumeResponse {
  @override
  final DateTime createdAt;
  @override
  final int id;
  @override
  final String name;
  @override
  final String resumeText;
  @override
  final DateTime updatedAt;
  @override
  final int userId;

  factory _$UserResumeResponse([
    void Function(UserResumeResponseBuilder)? updates,
  ]) => (UserResumeResponseBuilder()..update(updates))._build();

  _$UserResumeResponse._({
    required this.createdAt,
    required this.id,
    required this.name,
    required this.resumeText,
    required this.updatedAt,
    required this.userId,
  }) : super._();
  @override
  UserResumeResponse rebuild(
    void Function(UserResumeResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UserResumeResponseBuilder toBuilder() =>
      UserResumeResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserResumeResponse &&
        createdAt == other.createdAt &&
        id == other.id &&
        name == other.name &&
        resumeText == other.resumeText &&
        updatedAt == other.updatedAt &&
        userId == other.userId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, resumeText.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserResumeResponse')
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('name', name)
          ..add('resumeText', resumeText)
          ..add('updatedAt', updatedAt)
          ..add('userId', userId))
        .toString();
  }
}

class UserResumeResponseBuilder
    implements Builder<UserResumeResponse, UserResumeResponseBuilder> {
  _$UserResumeResponse? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _resumeText;
  String? get resumeText => _$this._resumeText;
  set resumeText(String? resumeText) => _$this._resumeText = resumeText;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  UserResumeResponseBuilder() {
    UserResumeResponse._defaults(this);
  }

  UserResumeResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _id = $v.id;
      _name = $v.name;
      _resumeText = $v.resumeText;
      _updatedAt = $v.updatedAt;
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserResumeResponse other) {
    _$v = other as _$UserResumeResponse;
  }

  @override
  void update(void Function(UserResumeResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserResumeResponse build() => _build();

  _$UserResumeResponse _build() {
    final _$result =
        _$v ??
        _$UserResumeResponse._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'UserResumeResponse',
            'createdAt',
          ),
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'UserResumeResponse',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'UserResumeResponse',
            'name',
          ),
          resumeText: BuiltValueNullFieldError.checkNotNull(
            resumeText,
            r'UserResumeResponse',
            'resumeText',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'UserResumeResponse',
            'updatedAt',
          ),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'UserResumeResponse',
            'userId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
