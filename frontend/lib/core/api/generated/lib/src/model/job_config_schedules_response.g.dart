// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_config_schedules_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JobConfigSchedulesResponse extends JobConfigSchedulesResponse {
  @override
  final BuiltList<JobConfigScheduleInfo>? configs;

  factory _$JobConfigSchedulesResponse(
          [void Function(JobConfigSchedulesResponseBuilder)? updates]) =>
      (JobConfigSchedulesResponseBuilder()..update(updates))._build();

  _$JobConfigSchedulesResponse._({this.configs}) : super._();
  @override
  JobConfigSchedulesResponse rebuild(
          void Function(JobConfigSchedulesResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobConfigSchedulesResponseBuilder toBuilder() =>
      JobConfigSchedulesResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobConfigSchedulesResponse && configs == other.configs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, configs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JobConfigSchedulesResponse')
          ..add('configs', configs))
        .toString();
  }
}

class JobConfigSchedulesResponseBuilder
    implements
        Builder<JobConfigSchedulesResponse, JobConfigSchedulesResponseBuilder> {
  _$JobConfigSchedulesResponse? _$v;

  ListBuilder<JobConfigScheduleInfo>? _configs;
  ListBuilder<JobConfigScheduleInfo> get configs =>
      _$this._configs ??= ListBuilder<JobConfigScheduleInfo>();
  set configs(ListBuilder<JobConfigScheduleInfo>? configs) =>
      _$this._configs = configs;

  JobConfigSchedulesResponseBuilder() {
    JobConfigSchedulesResponse._defaults(this);
  }

  JobConfigSchedulesResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _configs = $v.configs?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobConfigSchedulesResponse other) {
    _$v = other as _$JobConfigSchedulesResponse;
  }

  @override
  void update(void Function(JobConfigSchedulesResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobConfigSchedulesResponse build() => _build();

  _$JobConfigSchedulesResponse _build() {
    _$JobConfigSchedulesResponse _$result;
    try {
      _$result = _$v ??
          _$JobConfigSchedulesResponse._(
            configs: _configs?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'configs';
        _configs?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'JobConfigSchedulesResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
