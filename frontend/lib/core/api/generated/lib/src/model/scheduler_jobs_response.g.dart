// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduler_jobs_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SchedulerJobsResponse extends SchedulerJobsResponse {
  @override
  final BuiltMap<String, ScheduleInfo>? jobConfigs;
  @override
  final BuiltMap<String, ScheduleInfo>? productPlatforms;

  factory _$SchedulerJobsResponse([
    void Function(SchedulerJobsResponseBuilder)? updates,
  ]) => (SchedulerJobsResponseBuilder()..update(updates))._build();

  _$SchedulerJobsResponse._({this.jobConfigs, this.productPlatforms})
    : super._();
  @override
  SchedulerJobsResponse rebuild(
    void Function(SchedulerJobsResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SchedulerJobsResponseBuilder toBuilder() =>
      SchedulerJobsResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SchedulerJobsResponse &&
        jobConfigs == other.jobConfigs &&
        productPlatforms == other.productPlatforms;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, jobConfigs.hashCode);
    _$hash = $jc(_$hash, productPlatforms.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SchedulerJobsResponse')
          ..add('jobConfigs', jobConfigs)
          ..add('productPlatforms', productPlatforms))
        .toString();
  }
}

class SchedulerJobsResponseBuilder
    implements Builder<SchedulerJobsResponse, SchedulerJobsResponseBuilder> {
  _$SchedulerJobsResponse? _$v;

  MapBuilder<String, ScheduleInfo>? _jobConfigs;
  MapBuilder<String, ScheduleInfo> get jobConfigs =>
      _$this._jobConfigs ??= MapBuilder<String, ScheduleInfo>();
  set jobConfigs(MapBuilder<String, ScheduleInfo>? jobConfigs) =>
      _$this._jobConfigs = jobConfigs;

  MapBuilder<String, ScheduleInfo>? _productPlatforms;
  MapBuilder<String, ScheduleInfo> get productPlatforms =>
      _$this._productPlatforms ??= MapBuilder<String, ScheduleInfo>();
  set productPlatforms(MapBuilder<String, ScheduleInfo>? productPlatforms) =>
      _$this._productPlatforms = productPlatforms;

  SchedulerJobsResponseBuilder() {
    SchedulerJobsResponse._defaults(this);
  }

  SchedulerJobsResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _jobConfigs = $v.jobConfigs?.toBuilder();
      _productPlatforms = $v.productPlatforms?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SchedulerJobsResponse other) {
    _$v = other as _$SchedulerJobsResponse;
  }

  @override
  void update(void Function(SchedulerJobsResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SchedulerJobsResponse build() => _build();

  _$SchedulerJobsResponse _build() {
    _$SchedulerJobsResponse _$result;
    try {
      _$result =
          _$v ??
          _$SchedulerJobsResponse._(
            jobConfigs: _jobConfigs?.build(),
            productPlatforms: _productPlatforms?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'jobConfigs';
        _jobConfigs?.build();
        _$failedField = 'productPlatforms';
        _productPlatforms?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SchedulerJobsResponse',
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
