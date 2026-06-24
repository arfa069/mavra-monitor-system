// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_platform_cron_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductPlatformCronCreate extends ProductPlatformCronCreate {
  @override
  final String platform;
  @override
  final String? cronExpression;
  @override
  final String? cronTimezone;

  factory _$ProductPlatformCronCreate([
    void Function(ProductPlatformCronCreateBuilder)? updates,
  ]) => (ProductPlatformCronCreateBuilder()..update(updates))._build();

  _$ProductPlatformCronCreate._({
    required this.platform,
    this.cronExpression,
    this.cronTimezone,
  }) : super._();
  @override
  ProductPlatformCronCreate rebuild(
    void Function(ProductPlatformCronCreateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductPlatformCronCreateBuilder toBuilder() =>
      ProductPlatformCronCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductPlatformCronCreate &&
        platform == other.platform &&
        cronExpression == other.cronExpression &&
        cronTimezone == other.cronTimezone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, cronExpression.hashCode);
    _$hash = $jc(_$hash, cronTimezone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductPlatformCronCreate')
          ..add('platform', platform)
          ..add('cronExpression', cronExpression)
          ..add('cronTimezone', cronTimezone))
        .toString();
  }
}

class ProductPlatformCronCreateBuilder
    implements
        Builder<ProductPlatformCronCreate, ProductPlatformCronCreateBuilder> {
  _$ProductPlatformCronCreate? _$v;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _cronExpression;
  String? get cronExpression => _$this._cronExpression;
  set cronExpression(String? cronExpression) =>
      _$this._cronExpression = cronExpression;

  String? _cronTimezone;
  String? get cronTimezone => _$this._cronTimezone;
  set cronTimezone(String? cronTimezone) => _$this._cronTimezone = cronTimezone;

  ProductPlatformCronCreateBuilder() {
    ProductPlatformCronCreate._defaults(this);
  }

  ProductPlatformCronCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platform = $v.platform;
      _cronExpression = $v.cronExpression;
      _cronTimezone = $v.cronTimezone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductPlatformCronCreate other) {
    _$v = other as _$ProductPlatformCronCreate;
  }

  @override
  void update(void Function(ProductPlatformCronCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductPlatformCronCreate build() => _build();

  _$ProductPlatformCronCreate _build() {
    final _$result =
        _$v ??
        _$ProductPlatformCronCreate._(
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'ProductPlatformCronCreate',
            'platform',
          ),
          cronExpression: cronExpression,
          cronTimezone: cronTimezone,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
