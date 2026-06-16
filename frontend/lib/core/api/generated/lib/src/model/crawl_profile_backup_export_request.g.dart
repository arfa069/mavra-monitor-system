// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_backup_export_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CrawlProfileBackupExportRequest
    extends CrawlProfileBackupExportRequest {
  @override
  final String password;

  factory _$CrawlProfileBackupExportRequest(
          [void Function(CrawlProfileBackupExportRequestBuilder)? updates]) =>
      (CrawlProfileBackupExportRequestBuilder()..update(updates))._build();

  _$CrawlProfileBackupExportRequest._({required this.password}) : super._();
  @override
  CrawlProfileBackupExportRequest rebuild(
          void Function(CrawlProfileBackupExportRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CrawlProfileBackupExportRequestBuilder toBuilder() =>
      CrawlProfileBackupExportRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileBackupExportRequest &&
        password == other.password;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileBackupExportRequest')
          ..add('password', password))
        .toString();
  }
}

class CrawlProfileBackupExportRequestBuilder
    implements
        Builder<CrawlProfileBackupExportRequest,
            CrawlProfileBackupExportRequestBuilder> {
  _$CrawlProfileBackupExportRequest? _$v;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  CrawlProfileBackupExportRequestBuilder() {
    CrawlProfileBackupExportRequest._defaults(this);
  }

  CrawlProfileBackupExportRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _password = $v.password;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileBackupExportRequest other) {
    _$v = other as _$CrawlProfileBackupExportRequest;
  }

  @override
  void update(void Function(CrawlProfileBackupExportRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileBackupExportRequest build() => _build();

  _$CrawlProfileBackupExportRequest _build() {
    final _$result = _$v ??
        _$CrawlProfileBackupExportRequest._(
          password: BuiltValueNullFieldError.checkNotNull(
              password, r'CrawlProfileBackupExportRequest', 'password'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
