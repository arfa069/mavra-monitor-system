// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductResponse extends ProductResponse {
  @override
  final bool active;
  @override
  final DateTime createdAt;
  @override
  final int id;
  @override
  final String platform;
  @override
  final String? title;
  @override
  final DateTime updatedAt;
  @override
  final String url;
  @override
  final int userId;

  factory _$ProductResponse([void Function(ProductResponseBuilder)? updates]) =>
      (ProductResponseBuilder()..update(updates))._build();

  _$ProductResponse._(
      {required this.active,
      required this.createdAt,
      required this.id,
      required this.platform,
      this.title,
      required this.updatedAt,
      required this.url,
      required this.userId})
      : super._();
  @override
  ProductResponse rebuild(void Function(ProductResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductResponseBuilder toBuilder() => ProductResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductResponse &&
        active == other.active &&
        createdAt == other.createdAt &&
        id == other.id &&
        platform == other.platform &&
        title == other.title &&
        updatedAt == other.updatedAt &&
        url == other.url &&
        userId == other.userId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductResponse')
          ..add('active', active)
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('platform', platform)
          ..add('title', title)
          ..add('updatedAt', updatedAt)
          ..add('url', url)
          ..add('userId', userId))
        .toString();
  }
}

class ProductResponseBuilder
    implements Builder<ProductResponse, ProductResponseBuilder> {
  _$ProductResponse? _$v;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  ProductResponseBuilder() {
    ProductResponse._defaults(this);
  }

  ProductResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _active = $v.active;
      _createdAt = $v.createdAt;
      _id = $v.id;
      _platform = $v.platform;
      _title = $v.title;
      _updatedAt = $v.updatedAt;
      _url = $v.url;
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductResponse other) {
    _$v = other as _$ProductResponse;
  }

  @override
  void update(void Function(ProductResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductResponse build() => _build();

  _$ProductResponse _build() {
    final _$result = _$v ??
        _$ProductResponse._(
          active: BuiltValueNullFieldError.checkNotNull(
              active, r'ProductResponse', 'active'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'ProductResponse', 'createdAt'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'ProductResponse', 'id'),
          platform: BuiltValueNullFieldError.checkNotNull(
              platform, r'ProductResponse', 'platform'),
          title: title,
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'ProductResponse', 'updatedAt'),
          url: BuiltValueNullFieldError.checkNotNull(
              url, r'ProductResponse', 'url'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'ProductResponse', 'userId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
