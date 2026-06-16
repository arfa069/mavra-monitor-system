// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_batch_create_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductBatchCreateItem extends ProductBatchCreateItem {
  @override
  final String url;
  @override
  final String? platform;
  @override
  final String? title;

  factory _$ProductBatchCreateItem(
          [void Function(ProductBatchCreateItemBuilder)? updates]) =>
      (ProductBatchCreateItemBuilder()..update(updates))._build();

  _$ProductBatchCreateItem._({required this.url, this.platform, this.title})
      : super._();
  @override
  ProductBatchCreateItem rebuild(
          void Function(ProductBatchCreateItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductBatchCreateItemBuilder toBuilder() =>
      ProductBatchCreateItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductBatchCreateItem &&
        url == other.url &&
        platform == other.platform &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductBatchCreateItem')
          ..add('url', url)
          ..add('platform', platform)
          ..add('title', title))
        .toString();
  }
}

class ProductBatchCreateItemBuilder
    implements Builder<ProductBatchCreateItem, ProductBatchCreateItemBuilder> {
  _$ProductBatchCreateItem? _$v;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  ProductBatchCreateItemBuilder() {
    ProductBatchCreateItem._defaults(this);
  }

  ProductBatchCreateItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _url = $v.url;
      _platform = $v.platform;
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductBatchCreateItem other) {
    _$v = other as _$ProductBatchCreateItem;
  }

  @override
  void update(void Function(ProductBatchCreateItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductBatchCreateItem build() => _build();

  _$ProductBatchCreateItem _build() {
    final _$result = _$v ??
        _$ProductBatchCreateItem._(
          url: BuiltValueNullFieldError.checkNotNull(
              url, r'ProductBatchCreateItem', 'url'),
          platform: platform,
          title: title,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
