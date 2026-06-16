//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'we_chat_unbound_response.g.dart';

/// Unbound WeChat account exchange result.
///
/// Properties:
/// * [tempToken] 
/// * [nextPath] 
/// * [status] 
@BuiltValue()
abstract class WeChatUnboundResponse implements Built<WeChatUnboundResponse, WeChatUnboundResponseBuilder> {
  @BuiltValueField(wireName: r'temp_token')
  String get tempToken;

  @BuiltValueField(wireName: r'next_path')
  String? get nextPath;

  @BuiltValueField(wireName: r'status')
  String? get status;

  WeChatUnboundResponse._();

  factory WeChatUnboundResponse([void updates(WeChatUnboundResponseBuilder b)]) = _$WeChatUnboundResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WeChatUnboundResponseBuilder b) => b
      ..nextPath = '/today'
      ..status = 'unbound';

  @BuiltValueSerializer(custom: true)
  static Serializer<WeChatUnboundResponse> get serializer => _$WeChatUnboundResponseSerializer();
}

class _$WeChatUnboundResponseSerializer implements PrimitiveSerializer<WeChatUnboundResponse> {
  @override
  final Iterable<Type> types = const [WeChatUnboundResponse, _$WeChatUnboundResponse];

  @override
  final String wireName = r'WeChatUnboundResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WeChatUnboundResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'temp_token';
    yield serializers.serialize(
      object.tempToken,
      specifiedType: const FullType(String),
    );
    if (object.nextPath != null) {
      yield r'next_path';
      yield serializers.serialize(
        object.nextPath,
        specifiedType: const FullType(String),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WeChatUnboundResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WeChatUnboundResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'temp_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tempToken = valueDes;
          break;
        case r'next_path':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nextPath = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  WeChatUnboundResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WeChatUnboundResponseBuilder();
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

