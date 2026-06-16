// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawler_worker_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CrawlerWorkerResponse extends CrawlerWorkerResponse {
  @override
  final String hostname;
  @override
  final String kind;
  @override
  final DateTime? lastHeartbeatAt;
  @override
  final int pid;
  @override
  final String? platform;
  @override
  final DateTime? startedAt;
  @override
  final String status;
  @override
  final DateTime? stoppedAt;
  @override
  final String workerId;

  factory _$CrawlerWorkerResponse(
          [void Function(CrawlerWorkerResponseBuilder)? updates]) =>
      (CrawlerWorkerResponseBuilder()..update(updates))._build();

  _$CrawlerWorkerResponse._(
      {required this.hostname,
      required this.kind,
      this.lastHeartbeatAt,
      required this.pid,
      this.platform,
      this.startedAt,
      required this.status,
      this.stoppedAt,
      required this.workerId})
      : super._();
  @override
  CrawlerWorkerResponse rebuild(
          void Function(CrawlerWorkerResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CrawlerWorkerResponseBuilder toBuilder() =>
      CrawlerWorkerResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlerWorkerResponse &&
        hostname == other.hostname &&
        kind == other.kind &&
        lastHeartbeatAt == other.lastHeartbeatAt &&
        pid == other.pid &&
        platform == other.platform &&
        startedAt == other.startedAt &&
        status == other.status &&
        stoppedAt == other.stoppedAt &&
        workerId == other.workerId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hostname.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, lastHeartbeatAt.hashCode);
    _$hash = $jc(_$hash, pid.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, startedAt.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, stoppedAt.hashCode);
    _$hash = $jc(_$hash, workerId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlerWorkerResponse')
          ..add('hostname', hostname)
          ..add('kind', kind)
          ..add('lastHeartbeatAt', lastHeartbeatAt)
          ..add('pid', pid)
          ..add('platform', platform)
          ..add('startedAt', startedAt)
          ..add('status', status)
          ..add('stoppedAt', stoppedAt)
          ..add('workerId', workerId))
        .toString();
  }
}

class CrawlerWorkerResponseBuilder
    implements Builder<CrawlerWorkerResponse, CrawlerWorkerResponseBuilder> {
  _$CrawlerWorkerResponse? _$v;

  String? _hostname;
  String? get hostname => _$this._hostname;
  set hostname(String? hostname) => _$this._hostname = hostname;

  String? _kind;
  String? get kind => _$this._kind;
  set kind(String? kind) => _$this._kind = kind;

  DateTime? _lastHeartbeatAt;
  DateTime? get lastHeartbeatAt => _$this._lastHeartbeatAt;
  set lastHeartbeatAt(DateTime? lastHeartbeatAt) =>
      _$this._lastHeartbeatAt = lastHeartbeatAt;

  int? _pid;
  int? get pid => _$this._pid;
  set pid(int? pid) => _$this._pid = pid;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  DateTime? _startedAt;
  DateTime? get startedAt => _$this._startedAt;
  set startedAt(DateTime? startedAt) => _$this._startedAt = startedAt;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  DateTime? _stoppedAt;
  DateTime? get stoppedAt => _$this._stoppedAt;
  set stoppedAt(DateTime? stoppedAt) => _$this._stoppedAt = stoppedAt;

  String? _workerId;
  String? get workerId => _$this._workerId;
  set workerId(String? workerId) => _$this._workerId = workerId;

  CrawlerWorkerResponseBuilder() {
    CrawlerWorkerResponse._defaults(this);
  }

  CrawlerWorkerResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hostname = $v.hostname;
      _kind = $v.kind;
      _lastHeartbeatAt = $v.lastHeartbeatAt;
      _pid = $v.pid;
      _platform = $v.platform;
      _startedAt = $v.startedAt;
      _status = $v.status;
      _stoppedAt = $v.stoppedAt;
      _workerId = $v.workerId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlerWorkerResponse other) {
    _$v = other as _$CrawlerWorkerResponse;
  }

  @override
  void update(void Function(CrawlerWorkerResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlerWorkerResponse build() => _build();

  _$CrawlerWorkerResponse _build() {
    final _$result = _$v ??
        _$CrawlerWorkerResponse._(
          hostname: BuiltValueNullFieldError.checkNotNull(
              hostname, r'CrawlerWorkerResponse', 'hostname'),
          kind: BuiltValueNullFieldError.checkNotNull(
              kind, r'CrawlerWorkerResponse', 'kind'),
          lastHeartbeatAt: lastHeartbeatAt,
          pid: BuiltValueNullFieldError.checkNotNull(
              pid, r'CrawlerWorkerResponse', 'pid'),
          platform: platform,
          startedAt: startedAt,
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'CrawlerWorkerResponse', 'status'),
          stoppedAt: stoppedAt,
          workerId: BuiltValueNullFieldError.checkNotNull(
              workerId, r'CrawlerWorkerResponse', 'workerId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
