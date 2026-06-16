// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'threshold_percent1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ThresholdPercent1 extends ThresholdPercent1 {
  @override
  final AnyOf anyOf;

  factory _$ThresholdPercent1([
    void Function(ThresholdPercent1Builder)? updates,
  ]) => (ThresholdPercent1Builder()..update(updates))._build();

  _$ThresholdPercent1._({required this.anyOf}) : super._();
  @override
  ThresholdPercent1 rebuild(void Function(ThresholdPercent1Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ThresholdPercent1Builder toBuilder() =>
      ThresholdPercent1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ThresholdPercent1 && anyOf == other.anyOf;
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
      r'ThresholdPercent1',
    )..add('anyOf', anyOf)).toString();
  }
}

class ThresholdPercent1Builder
    implements Builder<ThresholdPercent1, ThresholdPercent1Builder> {
  _$ThresholdPercent1? _$v;

  AnyOf? _anyOf;
  AnyOf? get anyOf => _$this._anyOf;
  set anyOf(AnyOf? anyOf) => _$this._anyOf = anyOf;

  ThresholdPercent1Builder() {
    ThresholdPercent1._defaults(this);
  }

  ThresholdPercent1Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _anyOf = $v.anyOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ThresholdPercent1 other) {
    _$v = other as _$ThresholdPercent1;
  }

  @override
  void update(void Function(ThresholdPercent1Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ThresholdPercent1 build() => _build();

  _$ThresholdPercent1 _build() {
    final _$result =
        _$v ??
        _$ThresholdPercent1._(
          anyOf: BuiltValueNullFieldError.checkNotNull(
            anyOf,
            r'ThresholdPercent1',
            'anyOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
