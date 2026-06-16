// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JobListResponse extends JobListResponse {
  @override
  final BuiltList<JobResponse> items;
  @override
  final int page;
  @override
  final int pageSize;
  @override
  final int total;

  factory _$JobListResponse([void Function(JobListResponseBuilder)? updates]) =>
      (JobListResponseBuilder()..update(updates))._build();

  _$JobListResponse._({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  }) : super._();
  @override
  JobListResponse rebuild(void Function(JobListResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobListResponseBuilder toBuilder() => JobListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobListResponse &&
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
    return (newBuiltValueToStringHelper(r'JobListResponse')
          ..add('items', items)
          ..add('page', page)
          ..add('pageSize', pageSize)
          ..add('total', total))
        .toString();
  }
}

class JobListResponseBuilder
    implements Builder<JobListResponse, JobListResponseBuilder> {
  _$JobListResponse? _$v;

  ListBuilder<JobResponse>? _items;
  ListBuilder<JobResponse> get items =>
      _$this._items ??= ListBuilder<JobResponse>();
  set items(ListBuilder<JobResponse>? items) => _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  JobListResponseBuilder() {
    JobListResponse._defaults(this);
  }

  JobListResponseBuilder get _$this {
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
  void replace(JobListResponse other) {
    _$v = other as _$JobListResponse;
  }

  @override
  void update(void Function(JobListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobListResponse build() => _build();

  _$JobListResponse _build() {
    _$JobListResponse _$result;
    try {
      _$result =
          _$v ??
          _$JobListResponse._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
              page,
              r'JobListResponse',
              'page',
            ),
            pageSize: BuiltValueNullFieldError.checkNotNull(
              pageSize,
              r'JobListResponse',
              'pageSize',
            ),
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'JobListResponse',
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
          r'JobListResponse',
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
