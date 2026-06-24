// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'threshold_percent.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ThresholdPercent extends ThresholdPercent {
  @override
  final AnyOf anyOf;

  factory _$ThresholdPercent([
    void Function(ThresholdPercentBuilder)? updates,
  ]) => (ThresholdPercentBuilder()..update(updates))._build();

  _$ThresholdPercent._({required this.anyOf}) : super._();
  @override
  ThresholdPercent rebuild(void Function(ThresholdPercentBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ThresholdPercentBuilder toBuilder() =>
      ThresholdPercentBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ThresholdPercent && anyOf == other.anyOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, anyOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ThresholdPercent',
    )..add('anyOf', anyOf)).toString();
  }
}

class ThresholdPercentBuilder
    implements Builder<ThresholdPercent, ThresholdPercentBuilder> {
  _$ThresholdPercent? _$v;

  AnyOf? _anyOf;
  AnyOf? get anyOf => _$this._anyOf;
  set anyOf(AnyOf? anyOf) => _$this._anyOf = anyOf;

  ThresholdPercentBuilder() {
    ThresholdPercent._defaults(this);
  }

  ThresholdPercentBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _anyOf = $v.anyOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ThresholdPercent other) {
    _$v = other as _$ThresholdPercent;
  }

  @override
  void update(void Function(ThresholdPercentBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ThresholdPercent build() => _build();

  _$ThresholdPercent _build() {
    final _$result =
        _$v ??
        _$ThresholdPercent._(
          anyOf: BuiltValueNullFieldError.checkNotNull(
            anyOf,
            r'ThresholdPercent',
            'anyOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
