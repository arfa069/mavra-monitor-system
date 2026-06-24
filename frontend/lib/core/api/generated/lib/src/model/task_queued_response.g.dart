// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_queued_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TaskQueuedResponseStatusEnum _$taskQueuedResponseStatusEnum_pending =
    const TaskQueuedResponseStatusEnum._('pending');
const TaskQueuedResponseStatusEnum _$taskQueuedResponseStatusEnum_skipped =
    const TaskQueuedResponseStatusEnum._('skipped');
const TaskQueuedResponseStatusEnum _$taskQueuedResponseStatusEnum_error =
    const TaskQueuedResponseStatusEnum._('error');

TaskQueuedResponseStatusEnum _$taskQueuedResponseStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'pending':
      return _$taskQueuedResponseStatusEnum_pending;
    case 'skipped':
      return _$taskQueuedResponseStatusEnum_skipped;
    case 'error':
      return _$taskQueuedResponseStatusEnum_error;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TaskQueuedResponseStatusEnum>
_$taskQueuedResponseStatusEnumValues =
    BuiltSet<TaskQueuedResponseStatusEnum>(const <TaskQueuedResponseStatusEnum>[
      _$taskQueuedResponseStatusEnum_pending,
      _$taskQueuedResponseStatusEnum_skipped,
      _$taskQueuedResponseStatusEnum_error,
    ]);

Serializer<TaskQueuedResponseStatusEnum>
_$taskQueuedResponseStatusEnumSerializer =
    _$TaskQueuedResponseStatusEnumSerializer();

class _$TaskQueuedResponseStatusEnumSerializer
    implements PrimitiveSerializer<TaskQueuedResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pending': 'pending',
    'skipped': 'skipped',
    'error': 'error',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'skipped': 'skipped',
    'error': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[TaskQueuedResponseStatusEnum];
  @override
  final String wireName = 'TaskQueuedResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    TaskQueuedResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TaskQueuedResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TaskQueuedResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$TaskQueuedResponse extends TaskQueuedResponse {
  @override
  final TaskQueuedResponseStatusEnum status;
  @override
  final String? message;
  @override
  final String? reason;
  @override
  final String? taskId;

  factory _$TaskQueuedResponse([
    void Function(TaskQueuedResponseBuilder)? updates,
  ]) => (TaskQueuedResponseBuilder()..update(updates))._build();

  _$TaskQueuedResponse._({
    required this.status,
    this.message,
    this.reason,
    this.taskId,
  }) : super._();
  @override
  TaskQueuedResponse rebuild(
    void Function(TaskQueuedResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TaskQueuedResponseBuilder toBuilder() =>
      TaskQueuedResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TaskQueuedResponse &&
        status == other.status &&
        message == other.message &&
        reason == other.reason &&
        taskId == other.taskId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, taskId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TaskQueuedResponse')
          ..add('status', status)
          ..add('message', message)
          ..add('reason', reason)
          ..add('taskId', taskId))
        .toString();
  }
}

class TaskQueuedResponseBuilder
    implements Builder<TaskQueuedResponse, TaskQueuedResponseBuilder> {
  _$TaskQueuedResponse? _$v;

  TaskQueuedResponseStatusEnum? _status;
  TaskQueuedResponseStatusEnum? get status => _$this._status;
  set status(TaskQueuedResponseStatusEnum? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  String? _taskId;
  String? get taskId => _$this._taskId;
  set taskId(String? taskId) => _$this._taskId = taskId;

  TaskQueuedResponseBuilder() {
    TaskQueuedResponse._defaults(this);
  }

  TaskQueuedResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _reason = $v.reason;
      _taskId = $v.taskId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TaskQueuedResponse other) {
    _$v = other as _$TaskQueuedResponse;
  }

  @override
  void update(void Function(TaskQueuedResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TaskQueuedResponse build() => _build();

  _$TaskQueuedResponse _build() {
    final _$result =
        _$v ??
        _$TaskQueuedResponse._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'TaskQueuedResponse',
            'status',
          ),
          message: message,
          reason: reason,
          taskId: taskId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
