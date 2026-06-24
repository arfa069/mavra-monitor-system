// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_platform_profile_binding_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductPlatformProfileBindingResponse
    extends ProductPlatformProfileBindingResponse {
  @override
  final String platform;
  @override
  final DateTime? createdAt;
  @override
  final String? profileKey;
  @override
  final String? profileLastError;
  @override
  final String? profileStatus;
  @override
  final DateTime? updatedAt;

  factory _$ProductPlatformProfileBindingResponse([
    void Function(ProductPlatformProfileBindingResponseBuilder)? updates,
  ]) => (ProductPlatformProfileBindingResponseBuilder()..update(updates))
      ._build();

  _$ProductPlatformProfileBindingResponse._({
    required this.platform,
    this.createdAt,
    this.profileKey,
    this.profileLastError,
    this.profileStatus,
    this.updatedAt,
  }) : super._();
  @override
  ProductPlatformProfileBindingResponse rebuild(
    void Function(ProductPlatformProfileBindingResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductPlatformProfileBindingResponseBuilder toBuilder() =>
      ProductPlatformProfileBindingResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductPlatformProfileBindingResponse &&
        platform == other.platform &&
        createdAt == other.createdAt &&
        profileKey == other.profileKey &&
        profileLastError == other.profileLastError &&
        profileStatus == other.profileStatus &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jc(_$hash, profileLastError.hashCode);
    _$hash = $jc(_$hash, profileStatus.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'ProductPlatformProfileBindingResponse',
          )
          ..add('platform', platform)
          ..add('createdAt', createdAt)
          ..add('profileKey', profileKey)
          ..add('profileLastError', profileLastError)
          ..add('profileStatus', profileStatus)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class ProductPlatformProfileBindingResponseBuilder
    implements
        Builder<
          ProductPlatformProfileBindingResponse,
          ProductPlatformProfileBindingResponseBuilder
        > {
  _$ProductPlatformProfileBindingResponse? _$v;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  String? _profileLastError;
  String? get profileLastError => _$this._profileLastError;
  set profileLastError(String? profileLastError) =>
      _$this._profileLastError = profileLastError;

  String? _profileStatus;
  String? get profileStatus => _$this._profileStatus;
  set profileStatus(String? profileStatus) =>
      _$this._profileStatus = profileStatus;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ProductPlatformProfileBindingResponseBuilder() {
    ProductPlatformProfileBindingResponse._defaults(this);
  }

  ProductPlatformProfileBindingResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platform = $v.platform;
      _createdAt = $v.createdAt;
      _profileKey = $v.profileKey;
      _profileLastError = $v.profileLastError;
      _profileStatus = $v.profileStatus;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductPlatformProfileBindingResponse other) {
    _$v = other as _$ProductPlatformProfileBindingResponse;
  }

  @override
  void update(
    void Function(ProductPlatformProfileBindingResponseBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  ProductPlatformProfileBindingResponse build() => _build();

  _$ProductPlatformProfileBindingResponse _build() {
    final _$result =
        _$v ??
        _$ProductPlatformProfileBindingResponse._(
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'ProductPlatformProfileBindingResponse',
            'platform',
          ),
          createdAt: createdAt,
          profileKey: profileKey,
          profileLastError: profileLastError,
          profileStatus: profileStatus,
          updatedAt: updatedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
