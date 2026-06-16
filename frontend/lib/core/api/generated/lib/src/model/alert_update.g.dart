// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AlertUpdate extends AlertUpdate {
  @override
  final bool? active;
  @override
  final ThresholdPercent1? thresholdPercent;

  factory _$AlertUpdate([void Function(AlertUpdateBuilder)? updates]) =>
      (AlertUpdateBuilder()..update(updates))._build();

  _$AlertUpdate._({this.active, this.thresholdPercent}) : super._();
  @override
  AlertUpdate rebuild(void Function(AlertUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertUpdateBuilder toBuilder() => AlertUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertUpdate &&
        active == other.active &&
        thresholdPercent == other.thresholdPercent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, thresholdPercent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AlertUpdate')
          ..add('active', active)
          ..add('thresholdPercent', thresholdPercent))
        .toString();
  }
}

class AlertUpdateBuilder implements Builder<AlertUpdate, AlertUpdateBuilder> {
  _$AlertUpdate? _$v;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  ThresholdPercent1Builder? _thresholdPercent;
  ThresholdPercent1Builder get thresholdPercent =>
      _$this._thresholdPercent ??= ThresholdPercent1Builder();
  set thresholdPercent(ThresholdPercent1Builder? thresholdPercent) =>
      _$this._thresholdPercent = thresholdPercent;

  AlertUpdateBuilder() {
    AlertUpdate._defaults(this);
  }

  AlertUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _active = $v.active;
      _thresholdPercent = $v.thresholdPercent?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertUpdate other) {
    _$v = other as _$AlertUpdate;
  }

  @override
  void update(void Function(AlertUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AlertUpdate build() => _build();

  _$AlertUpdate _build() {
    _$AlertUpdate _$result;
    try {
      _$result = _$v ??
          _$AlertUpdate._(
            active: active,
            thresholdPercent: _thresholdPercent?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'thresholdPercent';
        _thresholdPercent?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AlertUpdate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
