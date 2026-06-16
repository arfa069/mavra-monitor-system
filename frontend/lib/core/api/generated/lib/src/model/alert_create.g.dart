// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AlertCreate extends AlertCreate {
  @override
  final int productId;
  @override
  final bool? active;
  @override
  final ThresholdPercent? thresholdPercent;

  factory _$AlertCreate([void Function(AlertCreateBuilder)? updates]) =>
      (AlertCreateBuilder()..update(updates))._build();

  _$AlertCreate._({required this.productId, this.active, this.thresholdPercent})
      : super._();
  @override
  AlertCreate rebuild(void Function(AlertCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertCreateBuilder toBuilder() => AlertCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertCreate &&
        productId == other.productId &&
        active == other.active &&
        thresholdPercent == other.thresholdPercent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, thresholdPercent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AlertCreate')
          ..add('productId', productId)
          ..add('active', active)
          ..add('thresholdPercent', thresholdPercent))
        .toString();
  }
}

class AlertCreateBuilder implements Builder<AlertCreate, AlertCreateBuilder> {
  _$AlertCreate? _$v;

  int? _productId;
  int? get productId => _$this._productId;
  set productId(int? productId) => _$this._productId = productId;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  ThresholdPercentBuilder? _thresholdPercent;
  ThresholdPercentBuilder get thresholdPercent =>
      _$this._thresholdPercent ??= ThresholdPercentBuilder();
  set thresholdPercent(ThresholdPercentBuilder? thresholdPercent) =>
      _$this._thresholdPercent = thresholdPercent;

  AlertCreateBuilder() {
    AlertCreate._defaults(this);
  }

  AlertCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _productId = $v.productId;
      _active = $v.active;
      _thresholdPercent = $v.thresholdPercent?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertCreate other) {
    _$v = other as _$AlertCreate;
  }

  @override
  void update(void Function(AlertCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AlertCreate build() => _build();

  _$AlertCreate _build() {
    _$AlertCreate _$result;
    try {
      _$result = _$v ??
          _$AlertCreate._(
            productId: BuiltValueNullFieldError.checkNotNull(
                productId, r'AlertCreate', 'productId'),
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
            r'AlertCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
