// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_progress_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TaskProgressResponseStatusEnum _$taskProgressResponseStatusEnum_pending =
    const TaskProgressResponseStatusEnum._('pending');
const TaskProgressResponseStatusEnum _$taskProgressResponseStatusEnum_running =
    const TaskProgressResponseStatusEnum._('running');
const TaskProgressResponseStatusEnum
_$taskProgressResponseStatusEnum_completed =
    const TaskProgressResponseStatusEnum._('completed');
const TaskProgressResponseStatusEnum _$taskProgressResponseStatusEnum_failed =
    const TaskProgressResponseStatusEnum._('failed');
const TaskProgressResponseStatusEnum _$taskProgressResponseStatusEnum_error =
    const TaskProgressResponseStatusEnum._('error');

TaskProgressResponseStatusEnum _$taskProgressResponseStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'pending':
      return _$taskProgressResponseStatusEnum_pending;
    case 'running':
      return _$taskProgressResponseStatusEnum_running;
    case 'completed':
      return _$taskProgressResponseStatusEnum_completed;
    case 'failed':
      return _$taskProgressResponseStatusEnum_failed;
    case 'error':
      return _$taskProgressResponseStatusEnum_error;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TaskProgressResponseStatusEnum>
_$taskProgressResponseStatusEnumValues =
    BuiltSet<TaskProgressResponseStatusEnum>(
      const <TaskProgressResponseStatusEnum>[
        _$taskProgressResponseStatusEnum_pending,
        _$taskProgressResponseStatusEnum_running,
        _$taskProgressResponseStatusEnum_completed,
        _$taskProgressResponseStatusEnum_failed,
        _$taskProgressResponseStatusEnum_error,
      ],
    );

Serializer<TaskProgressResponseStatusEnum>
_$taskProgressResponseStatusEnumSerializer =
    _$TaskProgressResponseStatusEnumSerializer();

class _$TaskProgressResponseStatusEnumSerializer
    implements PrimitiveSerializer<TaskProgressResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pending': 'pending',
    'running': 'running',
    'completed': 'completed',
    'failed': 'failed',
    'error': 'error',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'running': 'running',
    'completed': 'completed',
    'failed': 'failed',
    'error': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[TaskProgressResponseStatusEnum];
  @override
  final String wireName = 'TaskProgressResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    TaskProgressResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TaskProgressResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TaskProgressResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$TaskProgressResponse extends TaskProgressResponse {
  @override
  final TaskProgressResponseStatusEnum status;
  @override
  final String taskId;
  @override
  final BuiltList<JsonObject?>? details;
  @override
  final int? errors;
  @override
  final DateTime? finishedAt;
  @override
  final DateTime? heartbeatAt;
  @override
  final DateTime? leaseUntil;
  @override
  final String? reason;
  @override
  final DateTime? startedAt;
  @override
  final int? success;
  @override
  final int? total;
  @override
  final String? workerId;

  factory _$TaskProgressResponse([
    void Function(TaskProgressResponseBuilder)? updates,
  ]) => (TaskProgressResponseBuilder()..update(updates))._build();

  _$TaskProgressResponse._({
    required this.status,
    required this.taskId,
    this.details,
    this.errors,
    this.finishedAt,
    this.heartbeatAt,
    this.leaseUntil,
    this.reason,
    this.startedAt,
    this.success,
    this.total,
    this.workerId,
  }) : super._();
  @override
  TaskProgressResponse rebuild(
    void Function(TaskProgressResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TaskProgressResponseBuilder toBuilder() =>
      TaskProgressResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TaskProgressResponse &&
        status == other.status &&
        taskId == other.taskId &&
        details == other.details &&
        errors == other.errors &&
        finishedAt == other.finishedAt &&
        heartbeatAt == other.heartbeatAt &&
        leaseUntil == other.leaseUntil &&
        reason == other.reason &&
        startedAt == other.startedAt &&
        success == other.success &&
        total == other.total &&
        workerId == other.workerId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, taskId.hashCode);
    _$hash = $jc(_$hash, details.hashCode);
    _$hash = $jc(_$hash, errors.hashCode);
    _$hash = $jc(_$hash, finishedAt.hashCode);
    _$hash = $jc(_$hash, heartbeatAt.hashCode);
    _$hash = $jc(_$hash, leaseUntil.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, startedAt.hashCode);
    _$hash = $jc(_$hash, success.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, workerId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TaskProgressResponse')
          ..add('status', status)
          ..add('taskId', taskId)
          ..add('details', details)
          ..add('errors', errors)
          ..add('finishedAt', finishedAt)
          ..add('heartbeatAt', heartbeatAt)
          ..add('leaseUntil', leaseUntil)
          ..add('reason', reason)
          ..add('startedAt', startedAt)
          ..add('success', success)
          ..add('total', total)
          ..add('workerId', workerId))
        .toString();
  }
}

class TaskProgressResponseBuilder
    implements Builder<TaskProgressResponse, TaskProgressResponseBuilder> {
  _$TaskProgressResponse? _$v;

  TaskProgressResponseStatusEnum? _status;
  TaskProgressResponseStatusEnum? get status => _$this._status;
  set status(TaskProgressResponseStatusEnum? status) => _$this._status = status;

  String? _taskId;
  String? get taskId => _$this._taskId;
  set taskId(String? taskId) => _$this._taskId = taskId;

  ListBuilder<JsonObject?>? _details;
  ListBuilder<JsonObject?> get details =>
      _$this._details ??= ListBuilder<JsonObject?>();
  set details(ListBuilder<JsonObject?>? details) => _$this._details = details;

  int? _errors;
  int? get errors => _$this._errors;
  set errors(int? errors) => _$this._errors = errors;

  DateTime? _finishedAt;
  DateTime? get finishedAt => _$this._finishedAt;
  set finishedAt(DateTime? finishedAt) => _$this._finishedAt = finishedAt;

  DateTime? _heartbeatAt;
  DateTime? get heartbeatAt => _$this._heartbeatAt;
  set heartbeatAt(DateTime? heartbeatAt) => _$this._heartbeatAt = heartbeatAt;

  DateTime? _leaseUntil;
  DateTime? get leaseUntil => _$this._leaseUntil;
  set leaseUntil(DateTime? leaseUntil) => _$this._leaseUntil = leaseUntil;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  DateTime? _startedAt;
  DateTime? get startedAt => _$this._startedAt;
  set startedAt(DateTime? startedAt) => _$this._startedAt = startedAt;

  int? _success;
  int? get success => _$this._success;
  set success(int? success) => _$this._success = success;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  String? _workerId;
  String? get workerId => _$this._workerId;
  set workerId(String? workerId) => _$this._workerId = workerId;

  TaskProgressResponseBuilder() {
    TaskProgressResponse._defaults(this);
  }

  TaskProgressResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _taskId = $v.taskId;
      _details = $v.details?.toBuilder();
      _errors = $v.errors;
      _finishedAt = $v.finishedAt;
      _heartbeatAt = $v.heartbeatAt;
      _leaseUntil = $v.leaseUntil;
      _reason = $v.reason;
      _startedAt = $v.startedAt;
      _success = $v.success;
      _total = $v.total;
      _workerId = $v.workerId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TaskProgressResponse other) {
    _$v = other as _$TaskProgressResponse;
  }

  @override
  void update(void Function(TaskProgressResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TaskProgressResponse build() => _build();

  _$TaskProgressResponse _build() {
    _$TaskProgressResponse _$result;
    try {
      _$result =
          _$v ??
          _$TaskProgressResponse._(
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'TaskProgressResponse',
              'status',
            ),
            taskId: BuiltValueNullFieldError.checkNotNull(
              taskId,
              r'TaskProgressResponse',
              'taskId',
            ),
            details: _details?.build(),
            errors: errors,
            finishedAt: finishedAt,
            heartbeatAt: heartbeatAt,
            leaseUntil: leaseUntil,
            reason: reason,
            startedAt: startedAt,
            success: success,
            total: total,
            workerId: workerId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'details';
        _details?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TaskProgressResponse',
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
