// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_operation_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BatchOperationResult extends BatchOperationResult {
  @override
  final bool success;
  @override
  final String? error;
  @override
  final int? id;
  @override
  final String? url;

  factory _$BatchOperationResult(
          [void Function(BatchOperationResultBuilder)? updates]) =>
      (BatchOperationResultBuilder()..update(updates))._build();

  _$BatchOperationResult._(
      {required this.success, this.error, this.id, this.url})
      : super._();
  @override
  BatchOperationResult rebuild(
          void Function(BatchOperationResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BatchOperationResultBuilder toBuilder() =>
      BatchOperationResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BatchOperationResult &&
        success == other.success &&
        error == other.error &&
        id == other.id &&
        url == other.url;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, success.hashCode);
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BatchOperationResult')
          ..add('success', success)
          ..add('error', error)
          ..add('id', id)
          ..add('url', url))
        .toString();
  }
}

class BatchOperationResultBuilder
    implements Builder<BatchOperationResult, BatchOperationResultBuilder> {
  _$BatchOperationResult? _$v;

  bool? _success;
  bool? get success => _$this._success;
  set success(bool? success) => _$this._success = success;

  String? _error;
  String? get error => _$this._error;
  set error(String? error) => _$this._error = error;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  BatchOperationResultBuilder() {
    BatchOperationResult._defaults(this);
  }

  BatchOperationResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _success = $v.success;
      _error = $v.error;
      _id = $v.id;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BatchOperationResult other) {
    _$v = other as _$BatchOperationResult;
  }

  @override
  void update(void Function(BatchOperationResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BatchOperationResult build() => _build();

  _$BatchOperationResult _build() {
    final _$result = _$v ??
        _$BatchOperationResult._(
          success: BuiltValueNullFieldError.checkNotNull(
              success, r'BatchOperationResult', 'success'),
          error: error,
          id: id,
          url: url,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
