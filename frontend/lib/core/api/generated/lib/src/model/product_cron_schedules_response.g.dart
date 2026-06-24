// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_cron_schedules_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductCronSchedulesResponse extends ProductCronSchedulesResponse {
  @override
  final BuiltMap<String, ScheduleInfo>? platforms;

  factory _$ProductCronSchedulesResponse([
    void Function(ProductCronSchedulesResponseBuilder)? updates,
  ]) => (ProductCronSchedulesResponseBuilder()..update(updates))._build();

  _$ProductCronSchedulesResponse._({this.platforms}) : super._();
  @override
  ProductCronSchedulesResponse rebuild(
    void Function(ProductCronSchedulesResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductCronSchedulesResponseBuilder toBuilder() =>
      ProductCronSchedulesResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductCronSchedulesResponse &&
        platforms == other.platforms;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platforms.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ProductCronSchedulesResponse',
    )..add('platforms', platforms)).toString();
  }
}

class ProductCronSchedulesResponseBuilder
    implements
        Builder<
          ProductCronSchedulesResponse,
          ProductCronSchedulesResponseBuilder
        > {
  _$ProductCronSchedulesResponse? _$v;

  MapBuilder<String, ScheduleInfo>? _platforms;
  MapBuilder<String, ScheduleInfo> get platforms =>
      _$this._platforms ??= MapBuilder<String, ScheduleInfo>();
  set platforms(MapBuilder<String, ScheduleInfo>? platforms) =>
      _$this._platforms = platforms;

  ProductCronSchedulesResponseBuilder() {
    ProductCronSchedulesResponse._defaults(this);
  }

  ProductCronSchedulesResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platforms = $v.platforms?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductCronSchedulesResponse other) {
    _$v = other as _$ProductCronSchedulesResponse;
  }

  @override
  void update(void Function(ProductCronSchedulesResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductCronSchedulesResponse build() => _build();

  _$ProductCronSchedulesResponse _build() {
    _$ProductCronSchedulesResponse _$result;
    try {
      _$result =
          _$v ??
          _$ProductCronSchedulesResponse._(platforms: _platforms?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'platforms';
        _platforms?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProductCronSchedulesResponse',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
