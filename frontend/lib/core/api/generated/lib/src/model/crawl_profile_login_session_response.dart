//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_login_session_response.g.dart';

/// CrawlProfileLoginSessionResponse
///
/// Properties:
/// * [platform] 
/// * [profileKey] 
/// * [startUrl] 
/// * [status] 
/// * [message] 
@BuiltValue()
abstract class CrawlProfileLoginSessionResponse implements Built<CrawlProfileLoginSessionResponse, CrawlProfileLoginSessionResponseBuilder> {
  @BuiltValueField(wireName: r'platform')
  String get platform;

  @BuiltValueField(wireName: r'profile_key')
  String get profileKey;

  @BuiltValueField(wireName: r'start_url')
  String get startUrl;

  @BuiltValueField(wireName: r'status')
  CrawlProfileLoginSessionResponseStatusEnum get status;
  // enum statusEnum {  active,  closed,  failed,  };

  @BuiltValueField(wireName: r'message')
  String? get message;

  CrawlProfileLoginSessionResponse._();

  factory CrawlProfileLoginSessionResponse([void updates(CrawlProfileLoginSessionResponseBuilder b)]) = _$CrawlProfileLoginSessionResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileLoginSessionResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileLoginSessionResponse> get serializer => _$CrawlProfileLoginSessionResponseSerializer();
}

class _$CrawlProfileLoginSessionResponseSerializer implements PrimitiveSerializer<CrawlProfileLoginSessionResponse> {
  @override
  final Iterable<Type> types = const [CrawlProfileLoginSessionResponse, _$CrawlProfileLoginSessionResponse];

  @override
  final String wireName = r'CrawlProfileLoginSessionResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileLoginSessionResponse object, {
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
    yield r'start_url';
    yield serializers.serialize(
      object.startUrl,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(CrawlProfileLoginSessionResponseStatusEnum),
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
    CrawlProfileLoginSessionResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileLoginSessionResponseBuilder result,
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
        case r'start_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.startUrl = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CrawlProfileLoginSessionResponseStatusEnum),
          ) as CrawlProfileLoginSessionResponseStatusEnum;
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
  CrawlProfileLoginSessionResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileLoginSessionResponseBuilder();
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

class CrawlProfileLoginSessionResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'active')
  static const CrawlProfileLoginSessionResponseStatusEnum active = _$crawlProfileLoginSessionResponseStatusEnum_active;
  @BuiltValueEnumConst(wireName: r'closed')
  static const CrawlProfileLoginSessionResponseStatusEnum closed = _$crawlProfileLoginSessionResponseStatusEnum_closed;
  @BuiltValueEnumConst(wireName: r'failed')
  static const CrawlProfileLoginSessionResponseStatusEnum failed = _$crawlProfileLoginSessionResponseStatusEnum_failed;

  static Serializer<CrawlProfileLoginSessionResponseStatusEnum> get serializer => _$crawlProfileLoginSessionResponseStatusEnumSerializer;

  const CrawlProfileLoginSessionResponseStatusEnum._(String name): super(name);

  static BuiltSet<CrawlProfileLoginSessionResponseStatusEnum> get values => _$crawlProfileLoginSessionResponseStatusEnumValues;
  static CrawlProfileLoginSessionResponseStatusEnum valueOf(String name) => _$crawlProfileLoginSessionResponseStatusEnumValueOf(name);
}

