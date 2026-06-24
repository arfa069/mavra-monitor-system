// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_backup_import_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CrawlProfileBackupImportResponse
    extends CrawlProfileBackupImportResponse {
  @override
  final bool imported;
  @override
  final String profileKey;

  factory _$CrawlProfileBackupImportResponse([
    void Function(CrawlProfileBackupImportResponseBuilder)? updates,
  ]) => (CrawlProfileBackupImportResponseBuilder()..update(updates))._build();

  _$CrawlProfileBackupImportResponse._({
    required this.imported,
    required this.profileKey,
  }) : super._();
  @override
  CrawlProfileBackupImportResponse rebuild(
    void Function(CrawlProfileBackupImportResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CrawlProfileBackupImportResponseBuilder toBuilder() =>
      CrawlProfileBackupImportResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileBackupImportResponse &&
        imported == other.imported &&
        profileKey == other.profileKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, imported.hashCode);
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileBackupImportResponse')
          ..add('imported', imported)
          ..add('profileKey', profileKey))
        .toString();
  }
}

class CrawlProfileBackupImportResponseBuilder
    implements
        Builder<
          CrawlProfileBackupImportResponse,
          CrawlProfileBackupImportResponseBuilder
        > {
  _$CrawlProfileBackupImportResponse? _$v;

  bool? _imported;
  bool? get imported => _$this._imported;
  set imported(bool? imported) => _$this._imported = imported;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  CrawlProfileBackupImportResponseBuilder() {
    CrawlProfileBackupImportResponse._defaults(this);
  }

  CrawlProfileBackupImportResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _imported = $v.imported;
      _profileKey = $v.profileKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileBackupImportResponse other) {
    _$v = other as _$CrawlProfileBackupImportResponse;
  }

  @override
  void update(void Function(CrawlProfileBackupImportResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileBackupImportResponse build() => _build();

  _$CrawlProfileBackupImportResponse _build() {
    final _$result =
        _$v ??
        _$CrawlProfileBackupImportResponse._(
          imported: BuiltValueNullFieldError.checkNotNull(
            imported,
            r'CrawlProfileBackupImportResponse',
            'imported',
          ),
          profileKey: BuiltValueNullFieldError.checkNotNull(
            profileKey,
            r'CrawlProfileBackupImportResponse',
            'profileKey',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
