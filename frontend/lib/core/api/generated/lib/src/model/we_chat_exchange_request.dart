//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/login_client_kind.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'we_chat_exchange_request.g.dart';

/// One-time WeChat callback exchange code.
///
/// Properties:
/// * [exchangeCode] 
/// * [clientKind] 
@BuiltValue()
abstract class WeChatExchangeRequest implements Built<WeChatExchangeRequest, WeChatExchangeRequestBuilder> {
  @BuiltValueField(wireName: r'exchange_code')
  String get exchangeCode;

  @BuiltValueField(wireName: r'client_kind')
  LoginClientKind? get clientKind;
  // enum clientKindEnum {  web,  native,  };

  WeChatExchangeRequest._();

  factory WeChatExchangeRequest([void updates(WeChatExchangeRequestBuilder b)]) = _$WeChatExchangeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WeChatExchangeRequestBuilder b) => b
      ..clientKind = LoginClientKind.web;

  @BuiltValueSerializer(custom: true)
  static Serializer<WeChatExchangeRequest> get serializer => _$WeChatExchangeRequestSerializer();
}

class _$WeChatExchangeRequestSerializer implements PrimitiveSerializer<WeChatExchangeRequest> {
  @override
  final Iterable<Type> types = const [WeChatExchangeRequest, _$WeChatExchangeRequest];

  @override
  final String wireName = r'WeChatExchangeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WeChatExchangeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'exchange_code';
    yield serializers.serialize(
      object.exchangeCode,
      specifiedType: const FullType(String),
    );
    if (object.clientKind != null) {
      yield r'client_kind';
      yield serializers.serialize(
        object.clientKind,
        specifiedType: const FullType(LoginClientKind),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WeChatExchangeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WeChatExchangeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'exchange_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.exchangeCode = valueDes;
          break;
        case r'client_kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(LoginClientKind),
          ) as LoginClientKind;
          result.clientKind = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WeChatExchangeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WeChatExchangeRequestBuilder();
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

