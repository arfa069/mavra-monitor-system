// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_config_cron_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JobConfigCronUpdate extends JobConfigCronUpdate {
  @override
  final String? cronExpression;
  @override
  final String? cronTimezone;

  factory _$JobConfigCronUpdate([
    void Function(JobConfigCronUpdateBuilder)? updates,
  ]) => (JobConfigCronUpdateBuilder()..update(updates))._build();

  _$JobConfigCronUpdate._({this.cronExpression, this.cronTimezone}) : super._();
  @override
  JobConfigCronUpdate rebuild(
    void Function(JobConfigCronUpdateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  JobConfigCronUpdateBuilder toBuilder() =>
      JobConfigCronUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobConfigCronUpdate &&
        cronExpression == other.cronExpression &&
        cronTimezone == other.cronTimezone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cronExpression.hashCode);
    _$hash = $jc(_$hash, cronTimezone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JobConfigCronUpdate')
          ..add('cronExpression', cronExpression)
          ..add('cronTimezone', cronTimezone))
        .toString();
  }
}

class JobConfigCronUpdateBuilder
    implements Builder<JobConfigCronUpdate, JobConfigCronUpdateBuilder> {
  _$JobConfigCronUpdate? _$v;

  String? _cronExpression;
  String? get cronExpression => _$this._cronExpression;
  set cronExpression(String? cronExpression) =>
      _$this._cronExpression = cronExpression;

  String? _cronTimezone;
  String? get cronTimezone => _$this._cronTimezone;
  set cronTimezone(String? cronTimezone) => _$this._cronTimezone = cronTimezone;

  JobConfigCronUpdateBuilder() {
    JobConfigCronUpdate._defaults(this);
  }

  JobConfigCronUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cronExpression = $v.cronExpression;
      _cronTimezone = $v.cronTimezone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobConfigCronUpdate other) {
    _$v = other as _$JobConfigCronUpdate;
  }

  @override
  void update(void Function(JobConfigCronUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobConfigCronUpdate build() => _build();

  _$JobConfigCronUpdate _build() {
    final _$result =
        _$v ??
        _$JobConfigCronUpdate._(
          cronExpression: cronExpression,
          cronTimezone: cronTimezone,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
