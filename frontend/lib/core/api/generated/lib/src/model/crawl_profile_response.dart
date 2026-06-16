//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_response.g.dart';

/// CrawlProfileResponse
///
/// Properties:
/// * [createdAt] 
/// * [lastError] 
/// * [lastUsedAt] 
/// * [leaseOwner] 
/// * [leaseTaskId] 
/// * [leaseUntil] 
/// * [platformHint] 
/// * [profileDir] 
/// * [profileKey] 
/// * [status] 
/// * [updatedAt] 
@BuiltValue()
abstract class CrawlProfileResponse implements Built<CrawlProfileResponse, CrawlProfileResponseBuilder> {
  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'last_error')
  String? get lastError;

  @BuiltValueField(wireName: r'last_used_at')
  DateTime? get lastUsedAt;

  @BuiltValueField(wireName: r'lease_owner')
  String? get leaseOwner;

  @BuiltValueField(wireName: r'lease_task_id')
  String? get leaseTaskId;

  @BuiltValueField(wireName: r'lease_until')
  DateTime? get leaseUntil;

  @BuiltValueField(wireName: r'platform_hint')
  String? get platformHint;

  @BuiltValueField(wireName: r'profile_dir')
  String get profileDir;

  @BuiltValueField(wireName: r'profile_key')
  String get profileKey;

  @BuiltValueField(wireName: r'status')
  CrawlProfileResponseStatusEnum get status;
  // enum statusEnum {  available,  leased,  login_required,  cooling_down,  disabled,  };

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  CrawlProfileResponse._();

  factory CrawlProfileResponse([void updates(CrawlProfileResponseBuilder b)]) = _$CrawlProfileResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileResponse> get serializer => _$CrawlProfileResponseSerializer();
}

class _$CrawlProfileResponseSerializer implements PrimitiveSerializer<CrawlProfileResponse> {
  @override
  final Iterable<Type> types = const [CrawlProfileResponse, _$CrawlProfileResponse];

  @override
  final String wireName = r'CrawlProfileResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'last_error';
    yield object.lastError == null ? null : serializers.serialize(
      object.lastError,
      specifiedType: const FullType.nullable(String),
    );
    yield r'last_used_at';
    yield object.lastUsedAt == null ? null : serializers.serialize(
      object.lastUsedAt,
      specifiedType: const FullType.nullable(DateTime),
    );
    yield r'lease_owner';
    yield object.leaseOwner == null ? null : serializers.serialize(
      object.leaseOwner,
      specifiedType: const FullType.nullable(String),
    );
    yield r'lease_task_id';
    yield object.leaseTaskId == null ? null : serializers.serialize(
      object.leaseTaskId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'lease_until';
    yield object.leaseUntil == null ? null : serializers.serialize(
      object.leaseUntil,
      specifiedType: const FullType.nullable(DateTime),
    );
    yield r'platform_hint';
    yield object.platformHint == null ? null : serializers.serialize(
      object.platformHint,
      specifiedType: const FullType.nullable(String),
    );
    yield r'profile_dir';
    yield serializers.serialize(
      object.profileDir,
      specifiedType: const FullType(String),
    );
    yield r'profile_key';
    yield serializers.serialize(
      object.profileKey,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(CrawlProfileResponseStatusEnum),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'last_error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastError = valueDes;
          break;
        case r'last_used_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastUsedAt = valueDes;
          break;
        case r'lease_owner':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.leaseOwner = valueDes;
          break;
        case r'lease_task_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.leaseTaskId = valueDes;
          break;
        case r'lease_until':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.leaseUntil = valueDes;
          break;
        case r'platform_hint':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.platformHint = valueDes;
          break;
        case r'profile_dir':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.profileDir = valueDes;
          break;
        case r'profile_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.profileKey = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CrawlProfileResponseStatusEnum),
          ) as CrawlProfileResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileResponseBuilder();
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

class CrawlProfileResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'available')
  static const CrawlProfileResponseStatusEnum available = _$crawlProfileResponseStatusEnum_available;
  @BuiltValueEnumConst(wireName: r'leased')
  static const CrawlProfileResponseStatusEnum leased = _$crawlProfileResponseStatusEnum_leased;
  @BuiltValueEnumConst(wireName: r'login_required')
  static const CrawlProfileResponseStatusEnum loginRequired = _$crawlProfileResponseStatusEnum_loginRequired;
  @BuiltValueEnumConst(wireName: r'cooling_down')
  static const CrawlProfileResponseStatusEnum coolingDown = _$crawlProfileResponseStatusEnum_coolingDown;
  @BuiltValueEnumConst(wireName: r'disabled')
  static const CrawlProfileResponseStatusEnum disabled = _$crawlProfileResponseStatusEnum_disabled;

  static Serializer<CrawlProfileResponseStatusEnum> get serializer => _$crawlProfileResponseStatusEnumSerializer;

  const CrawlProfileResponseStatusEnum._(String name): super(name);

  static BuiltSet<CrawlProfileResponseStatusEnum> get values => _$crawlProfileResponseStatusEnumValues;
  static CrawlProfileResponseStatusEnum valueOf(String name) => _$crawlProfileResponseStatusEnumValueOf(name);
}

