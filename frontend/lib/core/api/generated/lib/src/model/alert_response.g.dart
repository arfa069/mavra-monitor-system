// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AlertResponse extends AlertResponse {
  @override
  final bool active;
  @override
  final String alertType;
  @override
  final DateTime createdAt;
  @override
  final int id;
  @override
  final DateTime? lastNotifiedAt;
  @override
  final String? lastNotifiedPrice;
  @override
  final int productId;
  @override
  final String? thresholdPercent;
  @override
  final DateTime updatedAt;

  factory _$AlertResponse([void Function(AlertResponseBuilder)? updates]) =>
      (AlertResponseBuilder()..update(updates))._build();

  _$AlertResponse._(
      {required this.active,
      required this.alertType,
      required this.createdAt,
      required this.id,
      this.lastNotifiedAt,
      this.lastNotifiedPrice,
      required this.productId,
      this.thresholdPercent,
      required this.updatedAt})
      : super._();
  @override
  AlertResponse rebuild(void Function(AlertResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertResponseBuilder toBuilder() => AlertResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertResponse &&
        active == other.active &&
        alertType == other.alertType &&
        createdAt == other.createdAt &&
        id == other.id &&
        lastNotifiedAt == other.lastNotifiedAt &&
        lastNotifiedPrice == other.lastNotifiedPrice &&
        productId == other.productId &&
        thresholdPercent == other.thresholdPercent &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, alertType.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, lastNotifiedAt.hashCode);
    _$hash = $jc(_$hash, lastNotifiedPrice.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, thresholdPercent.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AlertResponse')
          ..add('active', active)
          ..add('alertType', alertType)
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('lastNotifiedAt', lastNotifiedAt)
          ..add('lastNotifiedPrice', lastNotifiedPrice)
          ..add('productId', productId)
          ..add('thresholdPercent', thresholdPercent)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class AlertResponseBuilder
    implements Builder<AlertResponse, AlertResponseBuilder> {
  _$AlertResponse? _$v;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  String? _alertType;
  String? get alertType => _$this._alertType;
  set alertType(String? alertType) => _$this._alertType = alertType;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  DateTime? _lastNotifiedAt;
  DateTime? get lastNotifiedAt => _$this._lastNotifiedAt;
  set lastNotifiedAt(DateTime? lastNotifiedAt) =>
      _$this._lastNotifiedAt = lastNotifiedAt;

  String? _lastNotifiedPrice;
  String? get lastNotifiedPrice => _$this._lastNotifiedPrice;
  set lastNotifiedPrice(String? lastNotifiedPrice) =>
      _$this._lastNotifiedPrice = lastNotifiedPrice;

  int? _productId;
  int? get productId => _$this._productId;
  set productId(int? productId) => _$this._productId = productId;

  String? _thresholdPercent;
  String? get thresholdPercent => _$this._thresholdPercent;
  set thresholdPercent(String? thresholdPercent) =>
      _$this._thresholdPercent = thresholdPercent;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  AlertResponseBuilder() {
    AlertResponse._defaults(this);
  }

  AlertResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _active = $v.active;
      _alertType = $v.alertType;
      _createdAt = $v.createdAt;
      _id = $v.id;
      _lastNotifiedAt = $v.lastNotifiedAt;
      _lastNotifiedPrice = $v.lastNotifiedPrice;
      _productId = $v.productId;
      _thresholdPercent = $v.thresholdPercent;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertResponse other) {
    _$v = other as _$AlertResponse;
  }

  @override
  void update(void Function(AlertResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AlertResponse build() => _build();

  _$AlertResponse _build() {
    final _$result = _$v ??
        _$AlertResponse._(
          active: BuiltValueNullFieldError.checkNotNull(
              active, r'AlertResponse', 'active'),
          alertType: BuiltValueNullFieldError.checkNotNull(
              alertType, r'AlertResponse', 'alertType'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'AlertResponse', 'createdAt'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'AlertResponse', 'id'),
          lastNotifiedAt: lastNotifiedAt,
          lastNotifiedPrice: lastNotifiedPrice,
          productId: BuiltValueNullFieldError.checkNotNull(
              productId, r'AlertResponse', 'productId'),
          thresholdPercent: thresholdPercent,
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'AlertResponse', 'updatedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
