// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_task_queued_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MatchTaskQueuedResponseStatusEnum
_$matchTaskQueuedResponseStatusEnum_pending =
    const MatchTaskQueuedResponseStatusEnum._('pending');
const MatchTaskQueuedResponseStatusEnum
_$matchTaskQueuedResponseStatusEnum_completed =
    const MatchTaskQueuedResponseStatusEnum._('completed');

MatchTaskQueuedResponseStatusEnum _$matchTaskQueuedResponseStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'pending':
      return _$matchTaskQueuedResponseStatusEnum_pending;
    case 'completed':
      return _$matchTaskQueuedResponseStatusEnum_completed;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<MatchTaskQueuedResponseStatusEnum>
_$matchTaskQueuedResponseStatusEnumValues =
    BuiltSet<MatchTaskQueuedResponseStatusEnum>(
      const <MatchTaskQueuedResponseStatusEnum>[
        _$matchTaskQueuedResponseStatusEnum_pending,
        _$matchTaskQueuedResponseStatusEnum_completed,
      ],
    );

Serializer<MatchTaskQueuedResponseStatusEnum>
_$matchTaskQueuedResponseStatusEnumSerializer =
    _$MatchTaskQueuedResponseStatusEnumSerializer();

class _$MatchTaskQueuedResponseStatusEnumSerializer
    implements PrimitiveSerializer<MatchTaskQueuedResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pending': 'pending',
    'completed': 'completed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'completed': 'completed',
  };

  @override
  final Iterable<Type> types = const <Type>[MatchTaskQueuedResponseStatusEnum];
  @override
  final String wireName = 'MatchTaskQueuedResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    MatchTaskQueuedResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  MatchTaskQueuedResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => MatchTaskQueuedResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$MatchTaskQueuedResponse extends MatchTaskQueuedResponse {
  @override
  final MatchTaskQueuedResponseStatusEnum status;
  @override
  final String? taskId;
  @override
  final int total;
  @override
  final String? reason;

  factory _$MatchTaskQueuedResponse([
    void Function(MatchTaskQueuedResponseBuilder)? updates,
  ]) => (MatchTaskQueuedResponseBuilder()..update(updates))._build();

  _$MatchTaskQueuedResponse._({
    required this.status,
    this.taskId,
    required this.total,
    this.reason,
  }) : super._();
  @override
  MatchTaskQueuedResponse rebuild(
    void Function(MatchTaskQueuedResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  MatchTaskQueuedResponseBuilder toBuilder() =>
      MatchTaskQueuedResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchTaskQueuedResponse &&
        status == other.status &&
        taskId == other.taskId &&
        total == other.total &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, taskId.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchTaskQueuedResponse')
          ..add('status', status)
          ..add('taskId', taskId)
          ..add('total', total)
          ..add('reason', reason))
        .toString();
  }
}

class MatchTaskQueuedResponseBuilder
    implements
        Builder<MatchTaskQueuedResponse, MatchTaskQueuedResponseBuilder> {
  _$MatchTaskQueuedResponse? _$v;

  MatchTaskQueuedResponseStatusEnum? _status;
  MatchTaskQueuedResponseStatusEnum? get status => _$this._status;
  set status(MatchTaskQueuedResponseStatusEnum? status) =>
      _$this._status = status;

  String? _taskId;
  String? get taskId => _$this._taskId;
  set taskId(String? taskId) => _$this._taskId = taskId;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  MatchTaskQueuedResponseBuilder() {
    MatchTaskQueuedResponse._defaults(this);
  }

  MatchTaskQueuedResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _taskId = $v.taskId;
      _total = $v.total;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchTaskQueuedResponse other) {
    _$v = other as _$MatchTaskQueuedResponse;
  }

  @override
  void update(void Function(MatchTaskQueuedResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchTaskQueuedResponse build() => _build();

  _$MatchTaskQueuedResponse _build() {
    final _$result =
        _$v ??
        _$MatchTaskQueuedResponse._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'MatchTaskQueuedResponse',
            'status',
          ),
          taskId: taskId,
          total: BuiltValueNullFieldError.checkNotNull(
            total,
            r'MatchTaskQueuedResponse',
            'total',
          ),
          reason: reason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
