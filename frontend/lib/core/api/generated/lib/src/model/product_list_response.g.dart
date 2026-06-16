// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductListResponse extends ProductListResponse {
  @override
  final bool hasNext;
  @override
  final bool hasPrev;
  @override
  final BuiltList<ProductResponse> items;
  @override
  final int page;
  @override
  final int pageSize;
  @override
  final int total;
  @override
  final int totalPages;

  factory _$ProductListResponse(
          [void Function(ProductListResponseBuilder)? updates]) =>
      (ProductListResponseBuilder()..update(updates))._build();

  _$ProductListResponse._(
      {required this.hasNext,
      required this.hasPrev,
      required this.items,
      required this.page,
      required this.pageSize,
      required this.total,
      required this.totalPages})
      : super._();
  @override
  ProductListResponse rebuild(
          void Function(ProductListResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductListResponseBuilder toBuilder() =>
      ProductListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductListResponse &&
        hasNext == other.hasNext &&
        hasPrev == other.hasPrev &&
        items == other.items &&
        page == other.page &&
        pageSize == other.pageSize &&
        total == other.total &&
        totalPages == other.totalPages;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hasNext.hashCode);
    _$hash = $jc(_$hash, hasPrev.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, pageSize.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, totalPages.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductListResponse')
          ..add('hasNext', hasNext)
          ..add('hasPrev', hasPrev)
          ..add('items', items)
          ..add('page', page)
          ..add('pageSize', pageSize)
          ..add('total', total)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class ProductListResponseBuilder
    implements Builder<ProductListResponse, ProductListResponseBuilder> {
  _$ProductListResponse? _$v;

  bool? _hasNext;
  bool? get hasNext => _$this._hasNext;
  set hasNext(bool? hasNext) => _$this._hasNext = hasNext;

  bool? _hasPrev;
  bool? get hasPrev => _$this._hasPrev;
  set hasPrev(bool? hasPrev) => _$this._hasPrev = hasPrev;

  ListBuilder<ProductResponse>? _items;
  ListBuilder<ProductResponse> get items =>
      _$this._items ??= ListBuilder<ProductResponse>();
  set items(ListBuilder<ProductResponse>? items) => _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _totalPages;
  int? get totalPages => _$this._totalPages;
  set totalPages(int? totalPages) => _$this._totalPages = totalPages;

  ProductListResponseBuilder() {
    ProductListResponse._defaults(this);
  }

  ProductListResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hasNext = $v.hasNext;
      _hasPrev = $v.hasPrev;
      _items = $v.items.toBuilder();
      _page = $v.page;
      _pageSize = $v.pageSize;
      _total = $v.total;
      _totalPages = $v.totalPages;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductListResponse other) {
    _$v = other as _$ProductListResponse;
  }

  @override
  void update(void Function(ProductListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductListResponse build() => _build();

  _$ProductListResponse _build() {
    _$ProductListResponse _$result;
    try {
      _$result = _$v ??
          _$ProductListResponse._(
            hasNext: BuiltValueNullFieldError.checkNotNull(
                hasNext, r'ProductListResponse', 'hasNext'),
            hasPrev: BuiltValueNullFieldError.checkNotNull(
                hasPrev, r'ProductListResponse', 'hasPrev'),
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'ProductListResponse', 'page'),
            pageSize: BuiltValueNullFieldError.checkNotNull(
                pageSize, r'ProductListResponse', 'pageSize'),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'ProductListResponse', 'total'),
            totalPages: BuiltValueNullFieldError.checkNotNull(
                totalPages, r'ProductListResponse', 'totalPages'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ProductListResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
