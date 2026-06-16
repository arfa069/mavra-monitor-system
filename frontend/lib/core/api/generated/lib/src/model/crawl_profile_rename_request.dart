//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_rename_request.g.dart';

/// CrawlProfileRenameRequest
///
/// Properties:
/// * [profileKey] 
@BuiltValue()
abstract class CrawlProfileRenameRequest implements Built<CrawlProfileRenameRequest, CrawlProfileRenameRequestBuilder> {
  @BuiltValueField(wireName: r'profile_key')
  String get profileKey;

  CrawlProfileRenameRequest._();

  factory CrawlProfileRenameRequest([void updates(CrawlProfileRenameRequestBuilder b)]) = _$CrawlProfileRenameRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileRenameRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileRenameRequest> get serializer => _$CrawlProfileRenameRequestSerializer();
}

class _$CrawlProfileRenameRequestSerializer implements PrimitiveSerializer<CrawlProfileRenameRequest> {
  @override
  final Iterable<Type> types = const [CrawlProfileRenameRequest, _$CrawlProfileRenameRequest];

  @override
  final String wireName = r'CrawlProfileRenameRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileRenameRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'profile_key';
    yield serializers.serialize(
      object.profileKey,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileRenameRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileRenameRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileRenameRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileRenameRequestBuilder();
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

