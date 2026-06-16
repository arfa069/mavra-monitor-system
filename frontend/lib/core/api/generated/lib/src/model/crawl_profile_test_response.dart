//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_test_response.g.dart';

/// CrawlProfileTestResponse
///
/// Properties:
/// * [platform] 
/// * [profileKey] 
/// * [status] 
/// * [message] 
@BuiltValue()
abstract class CrawlProfileTestResponse implements Built<CrawlProfileTestResponse, CrawlProfileTestResponseBuilder> {
  @BuiltValueField(wireName: r'platform')
  String get platform;

  @BuiltValueField(wireName: r'profile_key')
  String get profileKey;

  @BuiltValueField(wireName: r'status')
  CrawlProfileTestResponseStatusEnum get status;
  // enum statusEnum {  ready,  login_required,  risk_blocked,  error,  };

  @BuiltValueField(wireName: r'message')
  String? get message;

  CrawlProfileTestResponse._();

  factory CrawlProfileTestResponse([void updates(CrawlProfileTestResponseBuilder b)]) = _$CrawlProfileTestResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileTestResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileTestResponse> get serializer => _$CrawlProfileTestResponseSerializer();
}

class _$CrawlProfileTestResponseSerializer implements PrimitiveSerializer<CrawlProfileTestResponse> {
  @override
  final Iterable<Type> types = const [CrawlProfileTestResponse, _$CrawlProfileTestResponse];

  @override
  final String wireName = r'CrawlProfileTestResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileTestResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'platform';
    yield serializers.serialize(
      object.platform,
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
      specifiedType: const FullType(CrawlProfileTestResponseStatusEnum),
    );
    if (object.message != null) {
      yield r'message';
      yield serializers.serialize(
        object.message,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileTestResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileTestResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.platform = valueDes;
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
            specifiedType: const FullType(CrawlProfileTestResponseStatusEnum),
          ) as CrawlProfileTestResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileTestResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileTestResponseBuilder();
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

class CrawlProfileTestResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ready')
  static const CrawlProfileTestResponseStatusEnum ready = _$crawlProfileTestResponseStatusEnum_ready;
  @BuiltValueEnumConst(wireName: r'login_required')
  static const CrawlProfileTestResponseStatusEnum loginRequired = _$crawlProfileTestResponseStatusEnum_loginRequired;
  @BuiltValueEnumConst(wireName: r'risk_blocked')
  static const CrawlProfileTestResponseStatusEnum riskBlocked = _$crawlProfileTestResponseStatusEnum_riskBlocked;
  @BuiltValueEnumConst(wireName: r'error')
  static const CrawlProfileTestResponseStatusEnum error = _$crawlProfileTestResponseStatusEnum_error;

  static Serializer<CrawlProfileTestResponseStatusEnum> get serializer => _$crawlProfileTestResponseStatusEnumSerializer;

  const CrawlProfileTestResponseStatusEnum._(String name): super(name);

  static BuiltSet<CrawlProfileTestResponseStatusEnum> get values => _$crawlProfileTestResponseStatusEnumValues;
  static CrawlProfileTestResponseStatusEnum valueOf(String name) => _$crawlProfileTestResponseStatusEnumValueOf(name);
}

