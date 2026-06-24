// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_info.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ScheduleInfo extends ScheduleInfo {
  @override
  final String? cronExpression;
  @override
  final String? nextRunAt;

  factory _$ScheduleInfo([void Function(ScheduleInfoBuilder)? updates]) =>
      (ScheduleInfoBuilder()..update(updates))._build();

  _$ScheduleInfo._({this.cronExpression, this.nextRunAt}) : super._();
  @override
  ScheduleInfo rebuild(void Function(ScheduleInfoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ScheduleInfoBuilder toBuilder() => ScheduleInfoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ScheduleInfo &&
        cronExpression == other.cronExpression &&
        nextRunAt == other.nextRunAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cronExpression.hashCode);
    _$hash = $jc(_$hash, nextRunAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ScheduleInfo')
          ..add('cronExpression', cronExpression)
          ..add('nextRunAt', nextRunAt))
        .toString();
  }
}

class ScheduleInfoBuilder
    implements Builder<ScheduleInfo, ScheduleInfoBuilder> {
  _$ScheduleInfo? _$v;

  String? _cronExpression;
  String? get cronExpression => _$this._cronExpression;
  set cronExpression(String? cronExpression) =>
      _$this._cronExpression = cronExpression;

  String? _nextRunAt;
  String? get nextRunAt => _$this._nextRunAt;
  set nextRunAt(String? nextRunAt) => _$this._nextRunAt = nextRunAt;

  ScheduleInfoBuilder() {
    ScheduleInfo._defaults(this);
  }

  ScheduleInfoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cronExpression = $v.cronExpression;
      _nextRunAt = $v.nextRunAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ScheduleInfo other) {
    _$v = other as _$ScheduleInfo;
  }

  @override
  void update(void Function(ScheduleInfoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ScheduleInfo build() => _build();

  _$ScheduleInfo _build() {
    final _$result =
        _$v ??
        _$ScheduleInfo._(cronExpression: cronExpression, nextRunAt: nextRunAt);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
