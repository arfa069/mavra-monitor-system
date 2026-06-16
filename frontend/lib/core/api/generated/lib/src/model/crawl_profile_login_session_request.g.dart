// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_login_session_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CrawlProfileLoginSessionRequest
    extends CrawlProfileLoginSessionRequest {
  @override
  final String? platform;
  @override
  final String? startUrl;

  factory _$CrawlProfileLoginSessionRequest([
    void Function(CrawlProfileLoginSessionRequestBuilder)? updates,
  ]) => (CrawlProfileLoginSessionRequestBuilder()..update(updates))._build();

  _$CrawlProfileLoginSessionRequest._({this.platform, this.startUrl})
    : super._();
  @override
  CrawlProfileLoginSessionRequest rebuild(
    void Function(CrawlProfileLoginSessionRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CrawlProfileLoginSessionRequestBuilder toBuilder() =>
      CrawlProfileLoginSessionRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileLoginSessionRequest &&
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
    return (newBuiltValueToStringHelper(r'CrawlProfileLoginSessionRequest')
          ..add('platform', platform)
          ..add('startUrl', startUrl))
        .toString();
  }
}

class CrawlProfileLoginSessionRequestBuilder
    implements
        Builder<
          CrawlProfileLoginSessionRequest,
          CrawlProfileLoginSessionRequestBuilder
        > {
  _$CrawlProfileLoginSessionRequest? _$v;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _startUrl;
  String? get startUrl => _$this._startUrl;
  set startUrl(String? startUrl) => _$this._startUrl = startUrl;

  CrawlProfileLoginSessionRequestBuilder() {
    CrawlProfileLoginSessionRequest._defaults(this);
  }

  CrawlProfileLoginSessionRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platform = $v.platform;
      _startUrl = $v.startUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileLoginSessionRequest other) {
    _$v = other as _$CrawlProfileLoginSessionRequest;
  }

  @override
  void update(void Function(CrawlProfileLoginSessionRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileLoginSessionRequest build() => _build();

  _$CrawlProfileLoginSessionRequest _build() {
    final _$result =
        _$v ??
        _$CrawlProfileLoginSessionRequest._(
          platform: platform,
          startUrl: startUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
