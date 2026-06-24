// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_data_point.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrendDataPoint extends TrendDataPoint {
  @override
  final String label;
  @override
  final num value;

  factory _$TrendDataPoint([void Function(TrendDataPointBuilder)? updates]) =>
      (TrendDataPointBuilder()..update(updates))._build();

  _$TrendDataPoint._({required this.label, required this.value}) : super._();
  @override
  TrendDataPoint rebuild(void Function(TrendDataPointBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrendDataPointBuilder toBuilder() => TrendDataPointBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrendDataPoint &&
        label == other.label &&
        value == other.value;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrendDataPoint')
          ..add('label', label)
          ..add('value', value))
        .toString();
  }
}

class TrendDataPointBuilder
    implements Builder<TrendDataPoint, TrendDataPointBuilder> {
  _$TrendDataPoint? _$v;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  num? _value;
  num? get value => _$this._value;
  set value(num? value) => _$this._value = value;

  TrendDataPointBuilder() {
    TrendDataPoint._defaults(this);
  }

  TrendDataPointBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _label = $v.label;
      _value = $v.value;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrendDataPoint other) {
    _$v = other as _$TrendDataPoint;
  }

  @override
  void update(void Function(TrendDataPointBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrendDataPoint build() => _build();

  _$TrendDataPoint _build() {
    final _$result =
        _$v ??
        _$TrendDataPoint._(
          label: BuiltValueNullFieldError.checkNotNull(
            label,
            r'TrendDataPoint',
            'label',
          ),
          value: BuiltValueNullFieldError.checkNotNull(
            value,
            r'TrendDataPoint',
            'value',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
