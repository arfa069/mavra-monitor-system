// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleanup_result_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CleanupResultResponseStatusEnum
    _$cleanupResultResponseStatusEnum_completed =
    const CleanupResultResponseStatusEnum._('completed');

CleanupResultResponseStatusEnum _$cleanupResultResponseStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'completed':
      return _$cleanupResultResponseStatusEnum_completed;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CleanupResultResponseStatusEnum>
    _$cleanupResultResponseStatusEnumValues = BuiltSet<
        CleanupResultResponseStatusEnum>(const <CleanupResultResponseStatusEnum>[
  _$cleanupResultResponseStatusEnum_completed,
]);

Serializer<CleanupResultResponseStatusEnum>
    _$cleanupResultResponseStatusEnumSerializer =
    _$CleanupResultResponseStatusEnumSerializer();

class _$CleanupResultResponseStatusEnumSerializer
    implements PrimitiveSerializer<CleanupResultResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'completed': 'completed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'completed': 'completed',
  };

  @override
  final Iterable<Type> types = const <Type>[CleanupResultResponseStatusEnum];
  @override
  final String wireName = 'CleanupResultResponseStatusEnum';

  @override
  Object serialize(
          Serializers serializers, CleanupResultResponseStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CleanupResultResponseStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CleanupResultResponseStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$CleanupResultResponse extends CleanupResultResponse {
  @override
  final DateTime cutoffDate;
  @override
  final int deletedCrawlLogs;
  @override
  final int deletedPriceHistory;
  @override
  final int retentionDays;
  @override
  final CleanupResultResponseStatusEnum status;

  factory _$CleanupResultResponse(
          [void Function(CleanupResultResponseBuilder)? updates]) =>
      (CleanupResultResponseBuilder()..update(updates))._build();

  _$CleanupResultResponse._(
      {required this.cutoffDate,
      required this.deletedCrawlLogs,
      required this.deletedPriceHistory,
      required this.retentionDays,
      required this.status})
      : super._();
  @override
  CleanupResultResponse rebuild(
          void Function(CleanupResultResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CleanupResultResponseBuilder toBuilder() =>
      CleanupResultResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CleanupResultResponse &&
        cutoffDate == other.cutoffDate &&
        deletedCrawlLogs == other.deletedCrawlLogs &&
        deletedPriceHistory == other.deletedPriceHistory &&
        retentionDays == other.retentionDays &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cutoffDate.hashCode);
    _$hash = $jc(_$hash, deletedCrawlLogs.hashCode);
    _$hash = $jc(_$hash, deletedPriceHistory.hashCode);
    _$hash = $jc(_$hash, retentionDays.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CleanupResultResponse')
          ..add('cutoffDate', cutoffDate)
          ..add('deletedCrawlLogs', deletedCrawlLogs)
          ..add('deletedPriceHistory', deletedPriceHistory)
          ..add('retentionDays', retentionDays)
          ..add('status', status))
        .toString();
  }
}

class CleanupResultResponseBuilder
    implements Builder<CleanupResultResponse, CleanupResultResponseBuilder> {
  _$CleanupResultResponse? _$v;

  DateTime? _cutoffDate;
  DateTime? get cutoffDate => _$this._cutoffDate;
  set cutoffDate(DateTime? cutoffDate) => _$this._cutoffDate = cutoffDate;

  int? _deletedCrawlLogs;
  int? get deletedCrawlLogs => _$this._deletedCrawlLogs;
  set deletedCrawlLogs(int? deletedCrawlLogs) =>
      _$this._deletedCrawlLogs = deletedCrawlLogs;

  int? _deletedPriceHistory;
  int? get deletedPriceHistory => _$this._deletedPriceHistory;
  set deletedPriceHistory(int? deletedPriceHistory) =>
      _$this._deletedPriceHistory = deletedPriceHistory;

  int? _retentionDays;
  int? get retentionDays => _$this._retentionDays;
  set retentionDays(int? retentionDays) =>
      _$this._retentionDays = retentionDays;

  CleanupResultResponseStatusEnum? _status;
  CleanupResultResponseStatusEnum? get status => _$this._status;
  set status(CleanupResultResponseStatusEnum? status) =>
      _$this._status = status;

  CleanupResultResponseBuilder() {
    CleanupResultResponse._defaults(this);
  }

  CleanupResultResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cutoffDate = $v.cutoffDate;
      _deletedCrawlLogs = $v.deletedCrawlLogs;
      _deletedPriceHistory = $v.deletedPriceHistory;
      _retentionDays = $v.retentionDays;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CleanupResultResponse other) {
    _$v = other as _$CleanupResultResponse;
  }

  @override
  void update(void Function(CleanupResultResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CleanupResultResponse build() => _build();

  _$CleanupResultResponse _build() {
    final _$result = _$v ??
        _$CleanupResultResponse._(
          cutoffDate: BuiltValueNullFieldError.checkNotNull(
              cutoffDate, r'CleanupResultResponse', 'cutoffDate'),
          deletedCrawlLogs: BuiltValueNullFieldError.checkNotNull(
              deletedCrawlLogs, r'CleanupResultResponse', 'deletedCrawlLogs'),
          deletedPriceHistory: BuiltValueNullFieldError.checkNotNull(
              deletedPriceHistory,
              r'CleanupResultResponse',
              'deletedPriceHistory'),
          retentionDays: BuiltValueNullFieldError.checkNotNull(
              retentionDays, r'CleanupResultResponse', 'retentionDays'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'CleanupResultResponse', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
