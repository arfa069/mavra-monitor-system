// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_analyze_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchAnalyzeRequest extends MatchAnalyzeRequest {
  @override
  final int resumeId;
  @override
  final BuiltList<int>? jobIds;

  factory _$MatchAnalyzeRequest([
    void Function(MatchAnalyzeRequestBuilder)? updates,
  ]) => (MatchAnalyzeRequestBuilder()..update(updates))._build();

  _$MatchAnalyzeRequest._({required this.resumeId, this.jobIds}) : super._();
  @override
  MatchAnalyzeRequest rebuild(
    void Function(MatchAnalyzeRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  MatchAnalyzeRequestBuilder toBuilder() =>
      MatchAnalyzeRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchAnalyzeRequest &&
        resumeId == other.resumeId &&
        jobIds == other.jobIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, resumeId.hashCode);
    _$hash = $jc(_$hash, jobIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchAnalyzeRequest')
          ..add('resumeId', resumeId)
          ..add('jobIds', jobIds))
        .toString();
  }
}

class MatchAnalyzeRequestBuilder
    implements Builder<MatchAnalyzeRequest, MatchAnalyzeRequestBuilder> {
  _$MatchAnalyzeRequest? _$v;

  int? _resumeId;
  int? get resumeId => _$this._resumeId;
  set resumeId(int? resumeId) => _$this._resumeId = resumeId;

  ListBuilder<int>? _jobIds;
  ListBuilder<int> get jobIds => _$this._jobIds ??= ListBuilder<int>();
  set jobIds(ListBuilder<int>? jobIds) => _$this._jobIds = jobIds;

  MatchAnalyzeRequestBuilder() {
    MatchAnalyzeRequest._defaults(this);
  }

  MatchAnalyzeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _resumeId = $v.resumeId;
      _jobIds = $v.jobIds?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchAnalyzeRequest other) {
    _$v = other as _$MatchAnalyzeRequest;
  }

  @override
  void update(void Function(MatchAnalyzeRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchAnalyzeRequest build() => _build();

  _$MatchAnalyzeRequest _build() {
    _$MatchAnalyzeRequest _$result;
    try {
      _$result =
          _$v ??
          _$MatchAnalyzeRequest._(
            resumeId: BuiltValueNullFieldError.checkNotNull(
              resumeId,
              r'MatchAnalyzeRequest',
              'resumeId',
            ),
            jobIds: _jobIds?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'jobIds';
        _jobIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'MatchAnalyzeRequest',
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
