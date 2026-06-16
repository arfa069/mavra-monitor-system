// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminUserListResponse extends AdminUserListResponse {
  @override
  final BuiltList<AdminUserResponse> items;
  @override
  final int page;
  @override
  final int pageSize;
  @override
  final int total;

  factory _$AdminUserListResponse([
    void Function(AdminUserListResponseBuilder)? updates,
  ]) => (AdminUserListResponseBuilder()..update(updates))._build();

  _$AdminUserListResponse._({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  }) : super._();
  @override
  AdminUserListResponse rebuild(
    void Function(AdminUserListResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminUserListResponseBuilder toBuilder() =>
      AdminUserListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminUserListResponse &&
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
    return (newBuiltValueToStringHelper(r'AdminUserListResponse')
          ..add('items', items)
          ..add('page', page)
          ..add('pageSize', pageSize)
          ..add('total', total))
        .toString();
  }
}

class AdminUserListResponseBuilder
    implements Builder<AdminUserListResponse, AdminUserListResponseBuilder> {
  _$AdminUserListResponse? _$v;

  ListBuilder<AdminUserResponse>? _items;
  ListBuilder<AdminUserResponse> get items =>
      _$this._items ??= ListBuilder<AdminUserResponse>();
  set items(ListBuilder<AdminUserResponse>? items) => _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  AdminUserListResponseBuilder() {
    AdminUserListResponse._defaults(this);
  }

  AdminUserListResponseBuilder get _$this {
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
  void replace(AdminUserListResponse other) {
    _$v = other as _$AdminUserListResponse;
  }

  @override
  void update(void Function(AdminUserListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminUserListResponse build() => _build();

  _$AdminUserListResponse _build() {
    _$AdminUserListResponse _$result;
    try {
      _$result =
          _$v ??
          _$AdminUserListResponse._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
              page,
              r'AdminUserListResponse',
              'page',
            ),
            pageSize: BuiltValueNullFieldError.checkNotNull(
              pageSize,
              r'AdminUserListResponse',
              'pageSize',
            ),
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'AdminUserListResponse',
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
          r'AdminUserListResponse',
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
