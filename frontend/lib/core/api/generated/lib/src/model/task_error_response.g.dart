// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_error_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TaskErrorResponseStatusEnum _$taskErrorResponseStatusEnum_error =
    const TaskErrorResponseStatusEnum._('error');

TaskErrorResponseStatusEnum _$taskErrorResponseStatusEnumValueOf(String name) {
  switch (name) {
    case 'error':
      return _$taskErrorResponseStatusEnum_error;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TaskErrorResponseStatusEnum>
    _$taskErrorResponseStatusEnumValues =
    BuiltSet<TaskErrorResponseStatusEnum>(const <TaskErrorResponseStatusEnum>[
  _$taskErrorResponseStatusEnum_error,
]);

Serializer<TaskErrorResponseStatusEnum>
    _$taskErrorResponseStatusEnumSerializer =
    _$TaskErrorResponseStatusEnumSerializer();

class _$TaskErrorResponseStatusEnumSerializer
    implements PrimitiveSerializer<TaskErrorResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'error': 'error',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'error': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[TaskErrorResponseStatusEnum];
  @override
  final String wireName = 'TaskErrorResponseStatusEnum';

  @override
  Object serialize(Serializers serializers, TaskErrorResponseStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TaskErrorResponseStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TaskErrorResponseStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$TaskErrorResponse extends TaskErrorResponse {
  @override
  final String reason;
  @override
  final TaskErrorResponseStatusEnum status;

  factory _$TaskErrorResponse(
          [void Function(TaskErrorResponseBuilder)? updates]) =>
      (TaskErrorResponseBuilder()..update(updates))._build();

  _$TaskErrorResponse._({required this.reason, required this.status})
      : super._();
  @override
  TaskErrorResponse rebuild(void Function(TaskErrorResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TaskErrorResponseBuilder toBuilder() =>
      TaskErrorResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TaskErrorResponse &&
        reason == other.reason &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TaskErrorResponse')
          ..add('reason', reason)
          ..add('status', status))
        .toString();
  }
}

class TaskErrorResponseBuilder
    implements Builder<TaskErrorResponse, TaskErrorResponseBuilder> {
  _$TaskErrorResponse? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  TaskErrorResponseStatusEnum? _status;
  TaskErrorResponseStatusEnum? get status => _$this._status;
  set status(TaskErrorResponseStatusEnum? status) => _$this._status = status;

  TaskErrorResponseBuilder() {
    TaskErrorResponse._defaults(this);
  }

  TaskErrorResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TaskErrorResponse other) {
    _$v = other as _$TaskErrorResponse;
  }

  @override
  void update(void Function(TaskErrorResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TaskErrorResponse build() => _build();

  _$TaskErrorResponse _build() {
    final _$result = _$v ??
        _$TaskErrorResponse._(
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'TaskErrorResponse', 'reason'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'TaskErrorResponse', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
