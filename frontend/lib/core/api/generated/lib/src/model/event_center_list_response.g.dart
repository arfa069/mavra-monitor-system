// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_center_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EventCenterListResponse extends EventCenterListResponse {
  @override
  final BuiltList<EventCenterItem> items;
  @override
  final int page;
  @override
  final int pageSize;
  @override
  final int total;

  factory _$EventCenterListResponse([
    void Function(EventCenterListResponseBuilder)? updates,
  ]) => (EventCenterListResponseBuilder()..update(updates))._build();

  _$EventCenterListResponse._({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  }) : super._();
  @override
  EventCenterListResponse rebuild(
    void Function(EventCenterListResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  EventCenterListResponseBuilder toBuilder() =>
      EventCenterListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EventCenterListResponse &&
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
    return (newBuiltValueToStringHelper(r'EventCenterListResponse')
          ..add('items', items)
          ..add('page', page)
          ..add('pageSize', pageSize)
          ..add('total', total))
        .toString();
  }
}

class EventCenterListResponseBuilder
    implements
        Builder<EventCenterListResponse, EventCenterListResponseBuilder> {
  _$EventCenterListResponse? _$v;

  ListBuilder<EventCenterItem>? _items;
  ListBuilder<EventCenterItem> get items =>
      _$this._items ??= ListBuilder<EventCenterItem>();
  set items(ListBuilder<EventCenterItem>? items) => _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  EventCenterListResponseBuilder() {
    EventCenterListResponse._defaults(this);
  }

  EventCenterListResponseBuilder get _$this {
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
  void replace(EventCenterListResponse other) {
    _$v = other as _$EventCenterListResponse;
  }

  @override
  void update(void Function(EventCenterListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EventCenterListResponse build() => _build();

  _$EventCenterListResponse _build() {
    _$EventCenterListResponse _$result;
    try {
      _$result =
          _$v ??
          _$EventCenterListResponse._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
              page,
              r'EventCenterListResponse',
              'page',
            ),
            pageSize: BuiltValueNullFieldError.checkNotNull(
              pageSize,
              r'EventCenterListResponse',
              'pageSize',
            ),
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'EventCenterListResponse',
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
          r'EventCenterListResponse',
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
