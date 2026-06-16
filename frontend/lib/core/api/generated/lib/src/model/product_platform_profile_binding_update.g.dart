// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_platform_profile_binding_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductPlatformProfileBindingUpdate
    extends ProductPlatformProfileBindingUpdate {
  @override
  final String profileKey;

  factory _$ProductPlatformProfileBindingUpdate(
          [void Function(ProductPlatformProfileBindingUpdateBuilder)?
              updates]) =>
      (ProductPlatformProfileBindingUpdateBuilder()..update(updates))._build();

  _$ProductPlatformProfileBindingUpdate._({required this.profileKey})
      : super._();
  @override
  ProductPlatformProfileBindingUpdate rebuild(
          void Function(ProductPlatformProfileBindingUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductPlatformProfileBindingUpdateBuilder toBuilder() =>
      ProductPlatformProfileBindingUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductPlatformProfileBindingUpdate &&
        profileKey == other.profileKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductPlatformProfileBindingUpdate')
          ..add('profileKey', profileKey))
        .toString();
  }
}

class ProductPlatformProfileBindingUpdateBuilder
    implements
        Builder<ProductPlatformProfileBindingUpdate,
            ProductPlatformProfileBindingUpdateBuilder> {
  _$ProductPlatformProfileBindingUpdate? _$v;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  ProductPlatformProfileBindingUpdateBuilder() {
    ProductPlatformProfileBindingUpdate._defaults(this);
  }

  ProductPlatformProfileBindingUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _profileKey = $v.profileKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductPlatformProfileBindingUpdate other) {
    _$v = other as _$ProductPlatformProfileBindingUpdate;
  }

  @override
  void update(
      void Function(ProductPlatformProfileBindingUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductPlatformProfileBindingUpdate build() => _build();

  _$ProductPlatformProfileBindingUpdate _build() {
    final _$result = _$v ??
        _$ProductPlatformProfileBindingUpdate._(
          profileKey: BuiltValueNullFieldError.checkNotNull(
              profileKey, r'ProductPlatformProfileBindingUpdate', 'profileKey'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
