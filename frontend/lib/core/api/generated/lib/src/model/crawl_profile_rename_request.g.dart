// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_rename_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CrawlProfileRenameRequest extends CrawlProfileRenameRequest {
  @override
  final String profileKey;

  factory _$CrawlProfileRenameRequest(
          [void Function(CrawlProfileRenameRequestBuilder)? updates]) =>
      (CrawlProfileRenameRequestBuilder()..update(updates))._build();

  _$CrawlProfileRenameRequest._({required this.profileKey}) : super._();
  @override
  CrawlProfileRenameRequest rebuild(
          void Function(CrawlProfileRenameRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CrawlProfileRenameRequestBuilder toBuilder() =>
      CrawlProfileRenameRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileRenameRequest && profileKey == other.profileKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileRenameRequest')
          ..add('profileKey', profileKey))
        .toString();
  }
}

class CrawlProfileRenameRequestBuilder
    implements
        Builder<CrawlProfileRenameRequest, CrawlProfileRenameRequestBuilder> {
  _$CrawlProfileRenameRequest? _$v;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  CrawlProfileRenameRequestBuilder() {
    CrawlProfileRenameRequest._defaults(this);
  }

  CrawlProfileRenameRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _profileKey = $v.profileKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileRenameRequest other) {
    _$v = other as _$CrawlProfileRenameRequest;
  }

  @override
  void update(void Function(CrawlProfileRenameRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileRenameRequest build() => _build();

  _$CrawlProfileRenameRequest _build() {
    final _$result = _$v ??
        _$CrawlProfileRenameRequest._(
          profileKey: BuiltValueNullFieldError.checkNotNull(
              profileKey, r'CrawlProfileRenameRequest', 'profileKey'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
