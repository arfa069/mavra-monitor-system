// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_test_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CrawlProfileTestRequest extends CrawlProfileTestRequest {
  @override
  final String? platform;
  @override
  final String? startUrl;

  factory _$CrawlProfileTestRequest([
    void Function(CrawlProfileTestRequestBuilder)? updates,
  ]) => (CrawlProfileTestRequestBuilder()..update(updates))._build();

  _$CrawlProfileTestRequest._({this.platform, this.startUrl}) : super._();
  @override
  CrawlProfileTestRequest rebuild(
    void Function(CrawlProfileTestRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CrawlProfileTestRequestBuilder toBuilder() =>
      CrawlProfileTestRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileTestRequest &&
        platform == other.platform &&
        startUrl == other.startUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, startUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileTestRequest')
          ..add('platform', platform)
          ..add('startUrl', startUrl))
        .toString();
  }
}

class CrawlProfileTestRequestBuilder
    implements
        Builder<CrawlProfileTestRequest, CrawlProfileTestRequestBuilder> {
  _$CrawlProfileTestRequest? _$v;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _startUrl;
  String? get startUrl => _$this._startUrl;
  set startUrl(String? startUrl) => _$this._startUrl = startUrl;

  CrawlProfileTestRequestBuilder() {
    CrawlProfileTestRequest._defaults(this);
  }

  CrawlProfileTestRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platform = $v.platform;
      _startUrl = $v.startUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileTestRequest other) {
    _$v = other as _$CrawlProfileTestRequest;
  }

  @override
  void update(void Function(CrawlProfileTestRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileTestRequest build() => _build();

  _$CrawlProfileTestRequest _build() {
    final _$result =
        _$v ??
        _$CrawlProfileTestRequest._(platform: platform, startUrl: startUrl);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
