// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductCreate extends ProductCreate {
  @override
  final String platform;
  @override
  final String url;
  @override
  final bool? active;
  @override
  final String? title;

  factory _$ProductCreate([void Function(ProductCreateBuilder)? updates]) =>
      (ProductCreateBuilder()..update(updates))._build();

  _$ProductCreate._(
      {required this.platform, required this.url, this.active, this.title})
      : super._();
  @override
  ProductCreate rebuild(void Function(ProductCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductCreateBuilder toBuilder() => ProductCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductCreate &&
        platform == other.platform &&
        url == other.url &&
        active == other.active &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductCreate')
          ..add('platform', platform)
          ..add('url', url)
          ..add('active', active)
          ..add('title', title))
        .toString();
  }
}

class ProductCreateBuilder
    implements Builder<ProductCreate, ProductCreateBuilder> {
  _$ProductCreate? _$v;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  ProductCreateBuilder() {
    ProductCreate._defaults(this);
  }

  ProductCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platform = $v.platform;
      _url = $v.url;
      _active = $v.active;
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductCreate other) {
    _$v = other as _$ProductCreate;
  }

  @override
  void update(void Function(ProductCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductCreate build() => _build();

  _$ProductCreate _build() {
    final _$result = _$v ??
        _$ProductCreate._(
          platform: BuiltValueNullFieldError.checkNotNull(
              platform, r'ProductCreate', 'platform'),
          url: BuiltValueNullFieldError.checkNotNull(
              url, r'ProductCreate', 'url'),
          active: active,
          title: title,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
