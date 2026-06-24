// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduler_status_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SchedulerStatusResponse extends SchedulerStatusResponse {
  @override
  final String scheduler;
  @override
  final SchedulerJobsResponse? jobs;
  @override
  final String? timezone;

  factory _$SchedulerStatusResponse([
    void Function(SchedulerStatusResponseBuilder)? updates,
  ]) => (SchedulerStatusResponseBuilder()..update(updates))._build();

  _$SchedulerStatusResponse._({
    required this.scheduler,
    this.jobs,
    this.timezone,
  }) : super._();
  @override
  SchedulerStatusResponse rebuild(
    void Function(SchedulerStatusResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SchedulerStatusResponseBuilder toBuilder() =>
      SchedulerStatusResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SchedulerStatusResponse &&
        scheduler == other.scheduler &&
        jobs == other.jobs &&
        timezone == other.timezone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, scheduler.hashCode);
    _$hash = $jc(_$hash, jobs.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SchedulerStatusResponse')
          ..add('scheduler', scheduler)
          ..add('jobs', jobs)
          ..add('timezone', timezone))
        .toString();
  }
}

class SchedulerStatusResponseBuilder
    implements
        Builder<SchedulerStatusResponse, SchedulerStatusResponseBuilder> {
  _$SchedulerStatusResponse? _$v;

  String? _scheduler;
  String? get scheduler => _$this._scheduler;
  set scheduler(String? scheduler) => _$this._scheduler = scheduler;

  SchedulerJobsResponseBuilder? _jobs;
  SchedulerJobsResponseBuilder get jobs =>
      _$this._jobs ??= SchedulerJobsResponseBuilder();
  set jobs(SchedulerJobsResponseBuilder? jobs) => _$this._jobs = jobs;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  SchedulerStatusResponseBuilder() {
    SchedulerStatusResponse._defaults(this);
  }

  SchedulerStatusResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _scheduler = $v.scheduler;
      _jobs = $v.jobs?.toBuilder();
      _timezone = $v.timezone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SchedulerStatusResponse other) {
    _$v = other as _$SchedulerStatusResponse;
  }

  @override
  void update(void Function(SchedulerStatusResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SchedulerStatusResponse build() => _build();

  _$SchedulerStatusResponse _build() {
    _$SchedulerStatusResponse _$result;
    try {
      _$result =
          _$v ??
          _$SchedulerStatusResponse._(
            scheduler: BuiltValueNullFieldError.checkNotNull(
              scheduler,
              r'SchedulerStatusResponse',
              'scheduler',
            ),
            jobs: _jobs?.build(),
            timezone: timezone,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'jobs';
        _jobs?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SchedulerStatusResponse',
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
