// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_alert.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RecentAlert extends RecentAlert {
  @override
  final bool active;
  @override
  final String alertType;
  @override
  final String? createdAt;
  @override
  final int id;
  @override
  final String message;
  @override
  final int? productId;
  @override
  final String? platform;
  @override
  final String? productTitle;

  factory _$RecentAlert([void Function(RecentAlertBuilder)? updates]) =>
      (RecentAlertBuilder()..update(updates))._build();

  _$RecentAlert._({
    required this.active,
    required this.alertType,
    this.createdAt,
    required this.id,
    required this.message,
    this.productId,
    this.platform,
    this.productTitle,
  }) : super._();
  @override
  RecentAlert rebuild(void Function(RecentAlertBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RecentAlertBuilder toBuilder() => RecentAlertBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RecentAlert &&
        active == other.active &&
        alertType == other.alertType &&
        createdAt == other.createdAt &&
        id == other.id &&
        message == other.message &&
        productId == other.productId &&
        platform == other.platform &&
        productTitle == other.productTitle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, alertType.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, productTitle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RecentAlert')
          ..add('active', active)
          ..add('alertType', alertType)
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('message', message)
          ..add('productId', productId)
          ..add('platform', platform)
          ..add('productTitle', productTitle))
        .toString();
  }
}

class RecentAlertBuilder implements Builder<RecentAlert, RecentAlertBuilder> {
  _$RecentAlert? _$v;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  String? _alertType;
  String? get alertType => _$this._alertType;
  set alertType(String? alertType) => _$this._alertType = alertType;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  int? _productId;
  int? get productId => _$this._productId;
  set productId(int? productId) => _$this._productId = productId;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _productTitle;
  String? get productTitle => _$this._productTitle;
  set productTitle(String? productTitle) => _$this._productTitle = productTitle;

  RecentAlertBuilder() {
    RecentAlert._defaults(this);
  }

  RecentAlertBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _active = $v.active;
      _alertType = $v.alertType;
      _createdAt = $v.createdAt;
      _id = $v.id;
      _message = $v.message;
      _productId = $v.productId;
      _platform = $v.platform;
      _productTitle = $v.productTitle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RecentAlert other) {
    _$v = other as _$RecentAlert;
  }

  @override
  void update(void Function(RecentAlertBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RecentAlert build() => _build();

  _$RecentAlert _build() {
    final _$result =
        _$v ??
        _$RecentAlert._(
          active: BuiltValueNullFieldError.checkNotNull(
            active,
            r'RecentAlert',
            'active',
          ),
          alertType: BuiltValueNullFieldError.checkNotNull(
            alertType,
            r'RecentAlert',
            'alertType',
          ),
          createdAt: createdAt,
          id: BuiltValueNullFieldError.checkNotNull(id, r'RecentAlert', 'id'),
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'RecentAlert',
            'message',
          ),
          productId: productId,
          platform: platform,
          productTitle: productTitle,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
