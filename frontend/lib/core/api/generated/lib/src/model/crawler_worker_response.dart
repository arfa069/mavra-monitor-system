//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawler_worker_response.g.dart';

/// CrawlerWorkerResponse
///
/// Properties:
/// * [hostname] 
/// * [kind] 
/// * [lastHeartbeatAt] 
/// * [pid] 
/// * [platform] 
/// * [startedAt] 
/// * [status] 
/// * [stoppedAt] 
/// * [workerId] 
@BuiltValue()
abstract class CrawlerWorkerResponse implements Built<CrawlerWorkerResponse, CrawlerWorkerResponseBuilder> {
  @BuiltValueField(wireName: r'hostname')
  String get hostname;

  @BuiltValueField(wireName: r'kind')
  String get kind;

  @BuiltValueField(wireName: r'last_heartbeat_at')
  DateTime? get lastHeartbeatAt;

  @BuiltValueField(wireName: r'pid')
  int get pid;

  @BuiltValueField(wireName: r'platform')
  String? get platform;

  @BuiltValueField(wireName: r'started_at')
  DateTime? get startedAt;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'stopped_at')
  DateTime? get stoppedAt;

  @BuiltValueField(wireName: r'worker_id')
  String get workerId;

  CrawlerWorkerResponse._();

  factory CrawlerWorkerResponse([void updates(CrawlerWorkerResponseBuilder b)]) = _$CrawlerWorkerResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlerWorkerResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlerWorkerResponse> get serializer => _$CrawlerWorkerResponseSerializer();
}

class _$CrawlerWorkerResponseSerializer implements PrimitiveSerializer<CrawlerWorkerResponse> {
  @override
  final Iterable<Type> types = const [CrawlerWorkerResponse, _$CrawlerWorkerResponse];

  @override
  final String wireName = r'CrawlerWorkerResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlerWorkerResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'hostname';
    yield serializers.serialize(
      object.hostname,
      specifiedType: const FullType(String),
    );
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(String),
    );
    yield r'last_heartbeat_at';
    yield object.lastHeartbeatAt == null ? null : serializers.serialize(
      object.lastHeartbeatAt,
      specifiedType: const FullType.nullable(DateTime),
    );
    yield r'pid';
    yield serializers.serialize(
      object.pid,
      specifiedType: const FullType(int),
    );
    yield r'platform';
    yield object.platform == null ? null : serializers.serialize(
      object.platform,
      specifiedType: const FullType.nullable(String),
    );
    yield r'started_at';
    yield object.startedAt == null ? null : serializers.serialize(
      object.startedAt,
      specifiedType: const FullType.nullable(DateTime),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    yield r'stopped_at';
    yield object.stoppedAt == null ? null : serializers.serialize(
      object.stoppedAt,
      specifiedType: const FullType.nullable(DateTime),
    );
    yield r'worker_id';
    yield serializers.serialize(
      object.workerId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlerWorkerResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlerWorkerResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'hostname':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.hostname = valueDes;
          break;
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.kind = valueDes;
          break;
        case r'last_heartbeat_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastHeartbeatAt = valueDes;
          break;
        case r'pid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.pid = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.platform = valueDes;
          break;
        case r'started_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.startedAt = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'stopped_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.stoppedAt = valueDes;
          break;
        case r'worker_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.workerId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlerWorkerResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlerWorkerResponseBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

