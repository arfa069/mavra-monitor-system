// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_post_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BlogPostListResponse extends BlogPostListResponse {
  @override
  final BuiltList<BlogPostListItem> items;
  @override
  final int page;
  @override
  final int size;
  @override
  final int total;

  factory _$BlogPostListResponse(
          [void Function(BlogPostListResponseBuilder)? updates]) =>
      (BlogPostListResponseBuilder()..update(updates))._build();

  _$BlogPostListResponse._(
      {required this.items,
      required this.page,
      required this.size,
      required this.total})
      : super._();
  @override
  BlogPostListResponse rebuild(
          void Function(BlogPostListResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BlogPostListResponseBuilder toBuilder() =>
      BlogPostListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BlogPostListResponse &&
        items == other.items &&
        page == other.page &&
        size == other.size &&
        total == other.total;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, size.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BlogPostListResponse')
          ..add('items', items)
          ..add('page', page)
          ..add('size', size)
          ..add('total', total))
        .toString();
  }
}

class BlogPostListResponseBuilder
    implements Builder<BlogPostListResponse, BlogPostListResponseBuilder> {
  _$BlogPostListResponse? _$v;

  ListBuilder<BlogPostListItem>? _items;
  ListBuilder<BlogPostListItem> get items =>
      _$this._items ??= ListBuilder<BlogPostListItem>();
  set items(ListBuilder<BlogPostListItem>? items) => _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _size;
  int? get size => _$this._size;
  set size(int? size) => _$this._size = size;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  BlogPostListResponseBuilder() {
    BlogPostListResponse._defaults(this);
  }

  BlogPostListResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page;
      _size = $v.size;
      _total = $v.total;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BlogPostListResponse other) {
    _$v = other as _$BlogPostListResponse;
  }

  @override
  void update(void Function(BlogPostListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BlogPostListResponse build() => _build();

  _$BlogPostListResponse _build() {
    _$BlogPostListResponse _$result;
    try {
      _$result = _$v ??
          _$BlogPostListResponse._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'BlogPostListResponse', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'BlogPostListResponse', 'size'),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'BlogPostListResponse', 'total'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BlogPostListResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
