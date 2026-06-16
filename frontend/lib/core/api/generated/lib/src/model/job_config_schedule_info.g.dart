// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_config_schedule_info.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JobConfigScheduleInfo extends JobConfigScheduleInfo {
  @override
  final int configId;
  @override
  final String? cronExpression;
  @override
  final String? nextRunAt;

  factory _$JobConfigScheduleInfo(
          [void Function(JobConfigScheduleInfoBuilder)? updates]) =>
      (JobConfigScheduleInfoBuilder()..update(updates))._build();

  _$JobConfigScheduleInfo._(
      {required this.configId, this.cronExpression, this.nextRunAt})
      : super._();
  @override
  JobConfigScheduleInfo rebuild(
          void Function(JobConfigScheduleInfoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobConfigScheduleInfoBuilder toBuilder() =>
      JobConfigScheduleInfoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobConfigScheduleInfo &&
        configId == other.configId &&
        cronExpression == other.cronExpression &&
        nextRunAt == other.nextRunAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, configId.hashCode);
    _$hash = $jc(_$hash, cronExpression.hashCode);
    _$hash = $jc(_$hash, nextRunAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JobConfigScheduleInfo')
          ..add('configId', configId)
          ..add('cronExpression', cronExpression)
          ..add('nextRunAt', nextRunAt))
        .toString();
  }
}

class JobConfigScheduleInfoBuilder
    implements Builder<JobConfigScheduleInfo, JobConfigScheduleInfoBuilder> {
  _$JobConfigScheduleInfo? _$v;

  int? _configId;
  int? get configId => _$this._configId;
  set configId(int? configId) => _$this._configId = configId;

  String? _cronExpression;
  String? get cronExpression => _$this._cronExpression;
  set cronExpression(String? cronExpression) =>
      _$this._cronExpression = cronExpression;

  String? _nextRunAt;
  String? get nextRunAt => _$this._nextRunAt;
  set nextRunAt(String? nextRunAt) => _$this._nextRunAt = nextRunAt;

  JobConfigScheduleInfoBuilder() {
    JobConfigScheduleInfo._defaults(this);
  }

  JobConfigScheduleInfoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _configId = $v.configId;
      _cronExpression = $v.cronExpression;
      _nextRunAt = $v.nextRunAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobConfigScheduleInfo other) {
    _$v = other as _$JobConfigScheduleInfo;
  }

  @override
  void update(void Function(JobConfigScheduleInfoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobConfigScheduleInfo build() => _build();

  _$JobConfigScheduleInfo _build() {
    final _$result = _$v ??
        _$JobConfigScheduleInfo._(
          configId: BuiltValueNullFieldError.checkNotNull(
              configId, r'JobConfigScheduleInfo', 'configId'),
          cronExpression: cronExpression,
          nextRunAt: nextRunAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
