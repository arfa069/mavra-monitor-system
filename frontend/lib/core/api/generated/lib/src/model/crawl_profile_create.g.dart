// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CrawlProfileCreate extends CrawlProfileCreate {
  @override
  final String profileKey;
  @override
  final String? platformHint;

  factory _$CrawlProfileCreate([
    void Function(CrawlProfileCreateBuilder)? updates,
  ]) => (CrawlProfileCreateBuilder()..update(updates))._build();

  _$CrawlProfileCreate._({required this.profileKey, this.platformHint})
    : super._();
  @override
  CrawlProfileCreate rebuild(
    void Function(CrawlProfileCreateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CrawlProfileCreateBuilder toBuilder() =>
      CrawlProfileCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileCreate &&
        profileKey == other.profileKey &&
        platformHint == other.platformHint;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jc(_$hash, platformHint.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileCreate')
          ..add('profileKey', profileKey)
          ..add('platformHint', platformHint))
        .toString();
  }
}

class CrawlProfileCreateBuilder
    implements Builder<CrawlProfileCreate, CrawlProfileCreateBuilder> {
  _$CrawlProfileCreate? _$v;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  String? _platformHint;
  String? get platformHint => _$this._platformHint;
  set platformHint(String? platformHint) => _$this._platformHint = platformHint;

  CrawlProfileCreateBuilder() {
    CrawlProfileCreate._defaults(this);
  }

  CrawlProfileCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _profileKey = $v.profileKey;
      _platformHint = $v.platformHint;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileCreate other) {
    _$v = other as _$CrawlProfileCreate;
  }

  @override
  void update(void Function(CrawlProfileCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileCreate build() => _build();

  _$CrawlProfileCreate _build() {
    final _$result =
        _$v ??
        _$CrawlProfileCreate._(
          profileKey: BuiltValueNullFieldError.checkNotNull(
            profileKey,
            r'CrawlProfileCreate',
            'profileKey',
          ),
          platformHint: platformHint,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
