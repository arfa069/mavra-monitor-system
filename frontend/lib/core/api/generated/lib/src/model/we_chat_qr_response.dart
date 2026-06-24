//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'we_chat_qr_response.g.dart';

/// Response schema for WeChat QR login bootstrap.
///
/// Properties:
/// * [qrUrl] 
/// * [state] 
@BuiltValue()
abstract class WeChatQrResponse implements Built<WeChatQrResponse, WeChatQrResponseBuilder> {
  @BuiltValueField(wireName: r'qr_url')
  String get qrUrl;

  @BuiltValueField(wireName: r'state')
  String get state;

  WeChatQrResponse._();

  factory WeChatQrResponse([void updates(WeChatQrResponseBuilder b)]) = _$WeChatQrResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WeChatQrResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WeChatQrResponse> get serializer => _$WeChatQrResponseSerializer();
}

class _$WeChatQrResponseSerializer implements PrimitiveSerializer<WeChatQrResponse> {
  @override
  final Iterable<Type> types = const [WeChatQrResponse, _$WeChatQrResponse];

  @override
  final String wireName = r'WeChatQrResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WeChatQrResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'qr_url';
    yield serializers.serialize(
      object.qrUrl,
      specifiedType: const FullType(String),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    WeChatQrResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WeChatQrResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'qr_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.qrUrl = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.state = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WeChatQrResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WeChatQrResponseBuilder();
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

