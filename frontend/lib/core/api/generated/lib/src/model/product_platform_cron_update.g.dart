// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_platform_cron_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductPlatformCronUpdate extends ProductPlatformCronUpdate {
  @override
  final String? cronExpression;
  @override
  final String? cronTimezone;

  factory _$ProductPlatformCronUpdate([
    void Function(ProductPlatformCronUpdateBuilder)? updates,
  ]) => (ProductPlatformCronUpdateBuilder()..update(updates))._build();

  _$ProductPlatformCronUpdate._({this.cronExpression, this.cronTimezone})
    : super._();
  @override
  ProductPlatformCronUpdate rebuild(
    void Function(ProductPlatformCronUpdateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductPlatformCronUpdateBuilder toBuilder() =>
      ProductPlatformCronUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductPlatformCronUpdate &&
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
    return (newBuiltValueToStringHelper(r'ProductPlatformCronUpdate')
          ..add('cronExpression', cronExpression)
          ..add('cronTimezone', cronTimezone))
        .toString();
  }
}

class ProductPlatformCronUpdateBuilder
    implements
        Builder<ProductPlatformCronUpdate, ProductPlatformCronUpdateBuilder> {
  _$ProductPlatformCronUpdate? _$v;

  String? _cronExpression;
  String? get cronExpression => _$this._cronExpression;
  set cronExpression(String? cronExpression) =>
      _$this._cronExpression = cronExpression;

  String? _cronTimezone;
  String? get cronTimezone => _$this._cronTimezone;
  set cronTimezone(String? cronTimezone) => _$this._cronTimezone = cronTimezone;

  ProductPlatformCronUpdateBuilder() {
    ProductPlatformCronUpdate._defaults(this);
  }

  ProductPlatformCronUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cronExpression = $v.cronExpression;
      _cronTimezone = $v.cronTimezone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductPlatformCronUpdate other) {
    _$v = other as _$ProductPlatformCronUpdate;
  }

  @override
  void update(void Function(ProductPlatformCronUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductPlatformCronUpdate build() => _build();

  _$ProductPlatformCronUpdate _build() {
    final _$result =
        _$v ??
        _$ProductPlatformCronUpdate._(
          cronExpression: cronExpression,
          cronTimezone: cronTimezone,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
