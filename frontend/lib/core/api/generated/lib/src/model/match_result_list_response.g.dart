// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchResultListResponse extends MatchResultListResponse {
  @override
  final BuiltList<MatchResultResponse> items;
  @override
  final int page;
  @override
  final int pageSize;
  @override
  final int total;

  factory _$MatchResultListResponse([
    void Function(MatchResultListResponseBuilder)? updates,
  ]) => (MatchResultListResponseBuilder()..update(updates))._build();

  _$MatchResultListResponse._({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  }) : super._();
  @override
  MatchResultListResponse rebuild(
    void Function(MatchResultListResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  MatchResultListResponseBuilder toBuilder() =>
      MatchResultListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchResultListResponse &&
        items == other.items &&
        page == other.page &&
        pageSize == other.pageSize &&
        total == other.total;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, pageSize.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchResultListResponse')
          ..add('items', items)
          ..add('page', page)
          ..add('pageSize', pageSize)
          ..add('total', total))
        .toString();
  }
}

class MatchResultListResponseBuilder
    implements
        Builder<MatchResultListResponse, MatchResultListResponseBuilder> {
  _$MatchResultListResponse? _$v;

  ListBuilder<MatchResultResponse>? _items;
  ListBuilder<MatchResultResponse> get items =>
      _$this._items ??= ListBuilder<MatchResultResponse>();
  set items(ListBuilder<MatchResultResponse>? items) => _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  MatchResultListResponseBuilder() {
    MatchResultListResponse._defaults(this);
  }

  MatchResultListResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page;
      _pageSize = $v.pageSize;
      _total = $v.total;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchResultListResponse other) {
    _$v = other as _$MatchResultListResponse;
  }

  @override
  void update(void Function(MatchResultListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchResultListResponse build() => _build();

  _$MatchResultListResponse _build() {
    _$MatchResultListResponse _$result;
    try {
      _$result =
          _$v ??
          _$MatchResultListResponse._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
              page,
              r'MatchResultListResponse',
              'page',
            ),
            pageSize: BuiltValueNullFieldError.checkNotNull(
              pageSize,
              r'MatchResultListResponse',
              'pageSize',
            ),
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'MatchResultListResponse',
              'total',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'MatchResultListResponse',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
