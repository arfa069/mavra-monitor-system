//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_update.g.dart';

/// CrawlProfileUpdate
///
/// Properties:
/// * [lastError] 
/// * [platformHint] 
/// * [status] 
@BuiltValue()
abstract class CrawlProfileUpdate implements Built<CrawlProfileUpdate, CrawlProfileUpdateBuilder> {
  @BuiltValueField(wireName: r'last_error')
  String? get lastError;

  @BuiltValueField(wireName: r'platform_hint')
  String? get platformHint;

  @BuiltValueField(wireName: r'status')
  CrawlProfileUpdateStatusEnum? get status;
  // enum statusEnum {  available,  login_required,  disabled,  };

  CrawlProfileUpdate._();

  factory CrawlProfileUpdate([void updates(CrawlProfileUpdateBuilder b)]) = _$CrawlProfileUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileUpdate> get serializer => _$CrawlProfileUpdateSerializer();
}

class _$CrawlProfileUpdateSerializer implements PrimitiveSerializer<CrawlProfileUpdate> {
  @override
  final Iterable<Type> types = const [CrawlProfileUpdate, _$CrawlProfileUpdate];

  @override
  final String wireName = r'CrawlProfileUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.lastError != null) {
      yield r'last_error';
      yield serializers.serialize(
        object.lastError,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.platformHint != null) {
      yield r'platform_hint';
      yield serializers.serialize(
        object.platformHint,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType.nullable(CrawlProfileUpdateStatusEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'last_error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastError = valueDes;
          break;
        case r'platform_hint':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.platformHint = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(CrawlProfileUpdateStatusEnum),
          ) as CrawlProfileUpdateStatusEnum?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileUpdateBuilder();
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

class CrawlProfileUpdateStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'available')
  static const CrawlProfileUpdateStatusEnum available = _$crawlProfileUpdateStatusEnum_available;
  @BuiltValueEnumConst(wireName: r'login_required')
  static const CrawlProfileUpdateStatusEnum loginRequired = _$crawlProfileUpdateStatusEnum_loginRequired;
  @BuiltValueEnumConst(wireName: r'disabled')
  static const CrawlProfileUpdateStatusEnum disabled = _$crawlProfileUpdateStatusEnum_disabled;

  static Serializer<CrawlProfileUpdateStatusEnum> get serializer => _$crawlProfileUpdateStatusEnumSerializer;

  const CrawlProfileUpdateStatusEnum._(String name): super(name);

  static BuiltSet<CrawlProfileUpdateStatusEnum> get values => _$crawlProfileUpdateStatusEnumValues;
  static CrawlProfileUpdateStatusEnum valueOf(String name) => _$crawlProfileUpdateStatusEnumValueOf(name);
}

