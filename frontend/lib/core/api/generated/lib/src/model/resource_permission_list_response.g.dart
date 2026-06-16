// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_permission_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResourcePermissionListResponse extends ResourcePermissionListResponse {
  @override
  final BuiltList<ResourcePermissionResponse> items;
  @override
  final int page;
  @override
  final int pageSize;
  @override
  final int total;

  factory _$ResourcePermissionListResponse(
          [void Function(ResourcePermissionListResponseBuilder)? updates]) =>
      (ResourcePermissionListResponseBuilder()..update(updates))._build();

  _$ResourcePermissionListResponse._(
      {required this.items,
      required this.page,
      required this.pageSize,
      required this.total})
      : super._();
  @override
  ResourcePermissionListResponse rebuild(
          void Function(ResourcePermissionListResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResourcePermissionListResponseBuilder toBuilder() =>
      ResourcePermissionListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResourcePermissionListResponse &&
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
    return (newBuiltValueToStringHelper(r'ResourcePermissionListResponse')
          ..add('items', items)
          ..add('page', page)
          ..add('pageSize', pageSize)
          ..add('total', total))
        .toString();
  }
}

class ResourcePermissionListResponseBuilder
    implements
        Builder<ResourcePermissionListResponse,
            ResourcePermissionListResponseBuilder> {
  _$ResourcePermissionListResponse? _$v;

  ListBuilder<ResourcePermissionResponse>? _items;
  ListBuilder<ResourcePermissionResponse> get items =>
      _$this._items ??= ListBuilder<ResourcePermissionResponse>();
  set items(ListBuilder<ResourcePermissionResponse>? items) =>
      _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  ResourcePermissionListResponseBuilder() {
    ResourcePermissionListResponse._defaults(this);
  }

  ResourcePermissionListResponseBuilder get _$this {
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
  void replace(ResourcePermissionListResponse other) {
    _$v = other as _$ResourcePermissionListResponse;
  }

  @override
  void update(void Function(ResourcePermissionListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResourcePermissionListResponse build() => _build();

  _$ResourcePermissionListResponse _build() {
    _$ResourcePermissionListResponse _$result;
    try {
      _$result = _$v ??
          _$ResourcePermissionListResponse._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'ResourcePermissionListResponse', 'page'),
            pageSize: BuiltValueNullFieldError.checkNotNull(
                pageSize, r'ResourcePermissionListResponse', 'pageSize'),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'ResourcePermissionListResponse', 'total'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ResourcePermissionListResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
