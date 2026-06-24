//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_create.g.dart';

/// CrawlProfileCreate
///
/// Properties:
/// * [profileKey] 
/// * [platformHint] 
@BuiltValue()
abstract class CrawlProfileCreate implements Built<CrawlProfileCreate, CrawlProfileCreateBuilder> {
  @BuiltValueField(wireName: r'profile_key')
  String get profileKey;

  @BuiltValueField(wireName: r'platform_hint')
  String? get platformHint;

  CrawlProfileCreate._();

  factory CrawlProfileCreate([void updates(CrawlProfileCreateBuilder b)]) = _$CrawlProfileCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileCreate> get serializer => _$CrawlProfileCreateSerializer();
}

class _$CrawlProfileCreateSerializer implements PrimitiveSerializer<CrawlProfileCreate> {
  @override
  final Iterable<Type> types = const [CrawlProfileCreate, _$CrawlProfileCreate];

  @override
  final String wireName = r'CrawlProfileCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'profile_key';
    yield serializers.serialize(
      object.profileKey,
      specifiedType: const FullType(String),
    );
    if (object.platformHint != null) {
      yield r'platform_hint';
      yield serializers.serialize(
        object.platformHint,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'profile_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.profileKey = valueDes;
          break;
        case r'platform_hint':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.platformHint = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileCreateBuilder();
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

