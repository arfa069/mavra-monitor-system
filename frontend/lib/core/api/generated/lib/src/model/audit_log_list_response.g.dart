// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuditLogListResponse extends AuditLogListResponse {
  @override
  final BuiltList<AuditLogResponse> items;
  @override
  final int page;
  @override
  final int pageSize;
  @override
  final int total;

  factory _$AuditLogListResponse([
    void Function(AuditLogListResponseBuilder)? updates,
  ]) => (AuditLogListResponseBuilder()..update(updates))._build();

  _$AuditLogListResponse._({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  }) : super._();
  @override
  AuditLogListResponse rebuild(
    void Function(AuditLogListResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AuditLogListResponseBuilder toBuilder() =>
      AuditLogListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditLogListResponse &&
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
    return (newBuiltValueToStringHelper(r'AuditLogListResponse')
          ..add('items', items)
          ..add('page', page)
          ..add('pageSize', pageSize)
          ..add('total', total))
        .toString();
  }
}

class AuditLogListResponseBuilder
    implements Builder<AuditLogListResponse, AuditLogListResponseBuilder> {
  _$AuditLogListResponse? _$v;

  ListBuilder<AuditLogResponse>? _items;
  ListBuilder<AuditLogResponse> get items =>
      _$this._items ??= ListBuilder<AuditLogResponse>();
  set items(ListBuilder<AuditLogResponse>? items) => _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  AuditLogListResponseBuilder() {
    AuditLogListResponse._defaults(this);
  }

  AuditLogListResponseBuilder get _$this {
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
  void replace(AuditLogListResponse other) {
    _$v = other as _$AuditLogListResponse;
  }

  @override
  void update(void Function(AuditLogListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuditLogListResponse build() => _build();

  _$AuditLogListResponse _build() {
    _$AuditLogListResponse _$result;
    try {
      _$result =
          _$v ??
          _$AuditLogListResponse._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
              page,
              r'AuditLogListResponse',
              'page',
            ),
            pageSize: BuiltValueNullFieldError.checkNotNull(
              pageSize,
              r'AuditLogListResponse',
              'pageSize',
            ),
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'AuditLogListResponse',
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
          r'AuditLogListResponse',
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
