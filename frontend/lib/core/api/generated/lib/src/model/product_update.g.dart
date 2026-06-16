// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductUpdate extends ProductUpdate {
  @override
  final bool? active;
  @override
  final String? platform;
  @override
  final String? title;
  @override
  final String? url;

  factory _$ProductUpdate([void Function(ProductUpdateBuilder)? updates]) =>
      (ProductUpdateBuilder()..update(updates))._build();

  _$ProductUpdate._({this.active, this.platform, this.title, this.url})
      : super._();
  @override
  ProductUpdate rebuild(void Function(ProductUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductUpdateBuilder toBuilder() => ProductUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductUpdate &&
        active == other.active &&
        platform == other.platform &&
        title == other.title &&
        url == other.url;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductUpdate')
          ..add('active', active)
          ..add('platform', platform)
          ..add('title', title)
          ..add('url', url))
        .toString();
  }
}

class ProductUpdateBuilder
    implements Builder<ProductUpdate, ProductUpdateBuilder> {
  _$ProductUpdate? _$v;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  ProductUpdateBuilder() {
    ProductUpdate._defaults(this);
  }

  ProductUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _active = $v.active;
      _platform = $v.platform;
      _title = $v.title;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductUpdate other) {
    _$v = other as _$ProductUpdate;
  }

  @override
  void update(void Function(ProductUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductUpdate build() => _build();

  _$ProductUpdate _build() {
    final _$result = _$v ??
        _$ProductUpdate._(
          active: active,
          platform: platform,
          title: title,
          url: url,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
