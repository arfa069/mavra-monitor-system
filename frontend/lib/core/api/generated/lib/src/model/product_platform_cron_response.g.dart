// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_platform_cron_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductPlatformCronResponse extends ProductPlatformCronResponse {
  @override
  final DateTime createdAt;
  @override
  final String? cronExpression;
  @override
  final String cronTimezone;
  @override
  final int id;
  @override
  final String platform;
  @override
  final String? profileKey;
  @override
  final DateTime updatedAt;
  @override
  final int userId;

  factory _$ProductPlatformCronResponse(
          [void Function(ProductPlatformCronResponseBuilder)? updates]) =>
      (ProductPlatformCronResponseBuilder()..update(updates))._build();

  _$ProductPlatformCronResponse._(
      {required this.createdAt,
      this.cronExpression,
      required this.cronTimezone,
      required this.id,
      required this.platform,
      this.profileKey,
      required this.updatedAt,
      required this.userId})
      : super._();
  @override
  ProductPlatformCronResponse rebuild(
          void Function(ProductPlatformCronResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductPlatformCronResponseBuilder toBuilder() =>
      ProductPlatformCronResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductPlatformCronResponse &&
        createdAt == other.createdAt &&
        cronExpression == other.cronExpression &&
        cronTimezone == other.cronTimezone &&
        id == other.id &&
        platform == other.platform &&
        profileKey == other.profileKey &&
        updatedAt == other.updatedAt &&
        userId == other.userId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, cronExpression.hashCode);
    _$hash = $jc(_$hash, cronTimezone.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductPlatformCronResponse')
          ..add('createdAt', createdAt)
          ..add('cronExpression', cronExpression)
          ..add('cronTimezone', cronTimezone)
          ..add('id', id)
          ..add('platform', platform)
          ..add('profileKey', profileKey)
          ..add('updatedAt', updatedAt)
          ..add('userId', userId))
        .toString();
  }
}

class ProductPlatformCronResponseBuilder
    implements
        Builder<ProductPlatformCronResponse,
            ProductPlatformCronResponseBuilder> {
  _$ProductPlatformCronResponse? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _cronExpression;
  String? get cronExpression => _$this._cronExpression;
  set cronExpression(String? cronExpression) =>
      _$this._cronExpression = cronExpression;

  String? _cronTimezone;
  String? get cronTimezone => _$this._cronTimezone;
  set cronTimezone(String? cronTimezone) => _$this._cronTimezone = cronTimezone;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  ProductPlatformCronResponseBuilder() {
    ProductPlatformCronResponse._defaults(this);
  }

  ProductPlatformCronResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _cronExpression = $v.cronExpression;
      _cronTimezone = $v.cronTimezone;
      _id = $v.id;
      _platform = $v.platform;
      _profileKey = $v.profileKey;
      _updatedAt = $v.updatedAt;
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductPlatformCronResponse other) {
    _$v = other as _$ProductPlatformCronResponse;
  }

  @override
  void update(void Function(ProductPlatformCronResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductPlatformCronResponse build() => _build();

  _$ProductPlatformCronResponse _build() {
    final _$result = _$v ??
        _$ProductPlatformCronResponse._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'ProductPlatformCronResponse', 'createdAt'),
          cronExpression: cronExpression,
          cronTimezone: BuiltValueNullFieldError.checkNotNull(
              cronTimezone, r'ProductPlatformCronResponse', 'cronTimezone'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'ProductPlatformCronResponse', 'id'),
          platform: BuiltValueNullFieldError.checkNotNull(
              platform, r'ProductPlatformCronResponse', 'platform'),
          profileKey: profileKey,
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'ProductPlatformCronResponse', 'updatedAt'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'ProductPlatformCronResponse', 'userId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
