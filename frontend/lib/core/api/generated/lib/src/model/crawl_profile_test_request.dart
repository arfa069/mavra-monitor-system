//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_test_request.g.dart';

/// CrawlProfileTestRequest
///
/// Properties:
/// * [platform] 
/// * [startUrl] 
@BuiltValue()
abstract class CrawlProfileTestRequest implements Built<CrawlProfileTestRequest, CrawlProfileTestRequestBuilder> {
  @BuiltValueField(wireName: r'platform')
  String? get platform;

  @BuiltValueField(wireName: r'start_url')
  String? get startUrl;

  CrawlProfileTestRequest._();

  factory CrawlProfileTestRequest([void updates(CrawlProfileTestRequestBuilder b)]) = _$CrawlProfileTestRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileTestRequestBuilder b) => b
      ..platform = 'boss';

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileTestRequest> get serializer => _$CrawlProfileTestRequestSerializer();
}

class _$CrawlProfileTestRequestSerializer implements PrimitiveSerializer<CrawlProfileTestRequest> {
  @override
  final Iterable<Type> types = const [CrawlProfileTestRequest, _$CrawlProfileTestRequest];

  @override
  final String wireName = r'CrawlProfileTestRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileTestRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.platform != null) {
      yield r'platform';
      yield serializers.serialize(
        object.platform,
        specifiedType: const FullType(String),
      );
    }
    if (object.startUrl != null) {
      yield r'start_url';
      yield serializers.serialize(
        object.startUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileTestRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileTestRequestBuilder result,
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
        case r'start_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.startUrl = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileTestRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileTestRequestBuilder();
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

