// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_crawl_log_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JobCrawlLogResponse extends JobCrawlLogResponse {
  @override
  final int id;
  @override
  final DateTime scrapedAt;
  @override
  final int searchConfigId;
  @override
  final String status;
  @override
  final String? errorMessage;
  @override
  final int? newJobsCount;
  @override
  final int? totalJobsCount;

  factory _$JobCrawlLogResponse(
          [void Function(JobCrawlLogResponseBuilder)? updates]) =>
      (JobCrawlLogResponseBuilder()..update(updates))._build();

  _$JobCrawlLogResponse._(
      {required this.id,
      required this.scrapedAt,
      required this.searchConfigId,
      required this.status,
      this.errorMessage,
      this.newJobsCount,
      this.totalJobsCount})
      : super._();
  @override
  JobCrawlLogResponse rebuild(
          void Function(JobCrawlLogResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobCrawlLogResponseBuilder toBuilder() =>
      JobCrawlLogResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobCrawlLogResponse &&
        id == other.id &&
        scrapedAt == other.scrapedAt &&
        searchConfigId == other.searchConfigId &&
        status == other.status &&
        errorMessage == other.errorMessage &&
        newJobsCount == other.newJobsCount &&
        totalJobsCount == other.totalJobsCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, scrapedAt.hashCode);
    _$hash = $jc(_$hash, searchConfigId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, errorMessage.hashCode);
    _$hash = $jc(_$hash, newJobsCount.hashCode);
    _$hash = $jc(_$hash, totalJobsCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JobCrawlLogResponse')
          ..add('id', id)
          ..add('scrapedAt', scrapedAt)
          ..add('searchConfigId', searchConfigId)
          ..add('status', status)
          ..add('errorMessage', errorMessage)
          ..add('newJobsCount', newJobsCount)
          ..add('totalJobsCount', totalJobsCount))
        .toString();
  }
}

class JobCrawlLogResponseBuilder
    implements Builder<JobCrawlLogResponse, JobCrawlLogResponseBuilder> {
  _$JobCrawlLogResponse? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  DateTime? _scrapedAt;
  DateTime? get scrapedAt => _$this._scrapedAt;
  set scrapedAt(DateTime? scrapedAt) => _$this._scrapedAt = scrapedAt;

  int? _searchConfigId;
  int? get searchConfigId => _$this._searchConfigId;
  set searchConfigId(int? searchConfigId) =>
      _$this._searchConfigId = searchConfigId;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _errorMessage;
  String? get errorMessage => _$this._errorMessage;
  set errorMessage(String? errorMessage) => _$this._errorMessage = errorMessage;

  int? _newJobsCount;
  int? get newJobsCount => _$this._newJobsCount;
  set newJobsCount(int? newJobsCount) => _$this._newJobsCount = newJobsCount;

  int? _totalJobsCount;
  int? get totalJobsCount => _$this._totalJobsCount;
  set totalJobsCount(int? totalJobsCount) =>
      _$this._totalJobsCount = totalJobsCount;

  JobCrawlLogResponseBuilder() {
    JobCrawlLogResponse._defaults(this);
  }

  JobCrawlLogResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _scrapedAt = $v.scrapedAt;
      _searchConfigId = $v.searchConfigId;
      _status = $v.status;
      _errorMessage = $v.errorMessage;
      _newJobsCount = $v.newJobsCount;
      _totalJobsCount = $v.totalJobsCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobCrawlLogResponse other) {
    _$v = other as _$JobCrawlLogResponse;
  }

  @override
  void update(void Function(JobCrawlLogResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobCrawlLogResponse build() => _build();

  _$JobCrawlLogResponse _build() {
    final _$result = _$v ??
        _$JobCrawlLogResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'JobCrawlLogResponse', 'id'),
          scrapedAt: BuiltValueNullFieldError.checkNotNull(
              scrapedAt, r'JobCrawlLogResponse', 'scrapedAt'),
          searchConfigId: BuiltValueNullFieldError.checkNotNull(
              searchConfigId, r'JobCrawlLogResponse', 'searchConfigId'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'JobCrawlLogResponse', 'status'),
          errorMessage: errorMessage,
          newJobsCount: newJobsCount,
          totalJobsCount: totalJobsCount,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
