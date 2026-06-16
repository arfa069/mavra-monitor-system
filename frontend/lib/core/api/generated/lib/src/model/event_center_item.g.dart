// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_center_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const EventCenterItemKindEnum _$eventCenterItemKindEnum_audit =
    const EventCenterItemKindEnum._('audit');
const EventCenterItemKindEnum _$eventCenterItemKindEnum_system =
    const EventCenterItemKindEnum._('system');
const EventCenterItemKindEnum _$eventCenterItemKindEnum_platform =
    const EventCenterItemKindEnum._('platform');

EventCenterItemKindEnum _$eventCenterItemKindEnumValueOf(String name) {
  switch (name) {
    case 'audit':
      return _$eventCenterItemKindEnum_audit;
    case 'system':
      return _$eventCenterItemKindEnum_system;
    case 'platform':
      return _$eventCenterItemKindEnum_platform;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<EventCenterItemKindEnum> _$eventCenterItemKindEnumValues =
    BuiltSet<EventCenterItemKindEnum>(const <EventCenterItemKindEnum>[
  _$eventCenterItemKindEnum_audit,
  _$eventCenterItemKindEnum_system,
  _$eventCenterItemKindEnum_platform,
]);

Serializer<EventCenterItemKindEnum> _$eventCenterItemKindEnumSerializer =
    _$EventCenterItemKindEnumSerializer();

class _$EventCenterItemKindEnumSerializer
    implements PrimitiveSerializer<EventCenterItemKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'audit': 'audit',
    'system': 'system',
    'platform': 'platform',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'audit': 'audit',
    'system': 'system',
    'platform': 'platform',
  };

  @override
  final Iterable<Type> types = const <Type>[EventCenterItemKindEnum];
  @override
  final String wireName = 'EventCenterItemKindEnum';

  @override
  Object serialize(Serializers serializers, EventCenterItemKindEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  EventCenterItemKindEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      EventCenterItemKindEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$EventCenterItem extends EventCenterItem {
  @override
  final String category;
  @override
  final String? entityId;
  @override
  final String? entityType;
  @override
  final String eventType;
  @override
  final String id;
  @override
  final EventCenterItemKindEnum kind;
  @override
  final String message;
  @override
  final DateTime occurredAt;
  @override
  final BuiltMap<String, JsonObject?>? payload;
  @override
  final String severity;
  @override
  final String source_;
  @override
  final String? status;
  @override
  final String? traceId;
  @override
  final int? userId;

  factory _$EventCenterItem([void Function(EventCenterItemBuilder)? updates]) =>
      (EventCenterItemBuilder()..update(updates))._build();

  _$EventCenterItem._(
      {required this.category,
      this.entityId,
      this.entityType,
      required this.eventType,
      required this.id,
      required this.kind,
      required this.message,
      required this.occurredAt,
      this.payload,
      required this.severity,
      required this.source_,
      this.status,
      this.traceId,
      this.userId})
      : super._();
  @override
  EventCenterItem rebuild(void Function(EventCenterItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EventCenterItemBuilder toBuilder() => EventCenterItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EventCenterItem &&
        category == other.category &&
        entityId == other.entityId &&
        entityType == other.entityType &&
        eventType == other.eventType &&
        id == other.id &&
        kind == other.kind &&
        message == other.message &&
        occurredAt == other.occurredAt &&
        payload == other.payload &&
        severity == other.severity &&
        source_ == other.source_ &&
        status == other.status &&
        traceId == other.traceId &&
        userId == other.userId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, entityId.hashCode);
    _$hash = $jc(_$hash, entityType.hashCode);
    _$hash = $jc(_$hash, eventType.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, occurredAt.hashCode);
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jc(_$hash, severity.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, traceId.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EventCenterItem')
          ..add('category', category)
          ..add('entityId', entityId)
          ..add('entityType', entityType)
          ..add('eventType', eventType)
          ..add('id', id)
          ..add('kind', kind)
          ..add('message', message)
          ..add('occurredAt', occurredAt)
          ..add('payload', payload)
          ..add('severity', severity)
          ..add('source_', source_)
          ..add('status', status)
          ..add('traceId', traceId)
          ..add('userId', userId))
        .toString();
  }
}

class EventCenterItemBuilder
    implements Builder<EventCenterItem, EventCenterItemBuilder> {
  _$EventCenterItem? _$v;

  String? _category;
  String? get category => _$this._category;
  set category(String? category) => _$this._category = category;

  String? _entityId;
  String? get entityId => _$this._entityId;
  set entityId(String? entityId) => _$this._entityId = entityId;

  String? _entityType;
  String? get entityType => _$this._entityType;
  set entityType(String? entityType) => _$this._entityType = entityType;

  String? _eventType;
  String? get eventType => _$this._eventType;
  set eventType(String? eventType) => _$this._eventType = eventType;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  EventCenterItemKindEnum? _kind;
  EventCenterItemKindEnum? get kind => _$this._kind;
  set kind(EventCenterItemKindEnum? kind) => _$this._kind = kind;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  DateTime? _occurredAt;
  DateTime? get occurredAt => _$this._occurredAt;
  set occurredAt(DateTime? occurredAt) => _$this._occurredAt = occurredAt;

  MapBuilder<String, JsonObject?>? _payload;
  MapBuilder<String, JsonObject?> get payload =>
      _$this._payload ??= MapBuilder<String, JsonObject?>();
  set payload(MapBuilder<String, JsonObject?>? payload) =>
      _$this._payload = payload;

  String? _severity;
  String? get severity => _$this._severity;
  set severity(String? severity) => _$this._severity = severity;

  String? _source_;
  String? get source_ => _$this._source_;
  set source_(String? source_) => _$this._source_ = source_;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  EventCenterItemBuilder() {
    EventCenterItem._defaults(this);
  }

  EventCenterItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _category = $v.category;
      _entityId = $v.entityId;
      _entityType = $v.entityType;
      _eventType = $v.eventType;
      _id = $v.id;
      _kind = $v.kind;
      _message = $v.message;
      _occurredAt = $v.occurredAt;
      _payload = $v.payload?.toBuilder();
      _severity = $v.severity;
      _source_ = $v.source_;
      _status = $v.status;
      _traceId = $v.traceId;
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EventCenterItem other) {
    _$v = other as _$EventCenterItem;
  }

  @override
  void update(void Function(EventCenterItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EventCenterItem build() => _build();

  _$EventCenterItem _build() {
    _$EventCenterItem _$result;
    try {
      _$result = _$v ??
          _$EventCenterItem._(
            category: BuiltValueNullFieldError.checkNotNull(
                category, r'EventCenterItem', 'category'),
            entityId: entityId,
            entityType: entityType,
            eventType: BuiltValueNullFieldError.checkNotNull(
                eventType, r'EventCenterItem', 'eventType'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'EventCenterItem', 'id'),
            kind: BuiltValueNullFieldError.checkNotNull(
                kind, r'EventCenterItem', 'kind'),
            message: BuiltValueNullFieldError.checkNotNull(
                message, r'EventCenterItem', 'message'),
            occurredAt: BuiltValueNullFieldError.checkNotNull(
                occurredAt, r'EventCenterItem', 'occurredAt'),
            payload: _payload?.build(),
            severity: BuiltValueNullFieldError.checkNotNull(
                severity, r'EventCenterItem', 'severity'),
            source_: BuiltValueNullFieldError.checkNotNull(
                source_, r'EventCenterItem', 'source_'),
            status: status,
            traceId: traceId,
            userId: userId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        _payload?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'EventCenterItem', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
