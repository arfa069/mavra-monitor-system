//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/auth_session_response.dart';
import 'package:mavra_api/src/model/we_chat_unbound_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'we_chat_exchange_response.g.dart';

/// Cross-platform WeChat exchange response.
///
/// Properties:
/// * [status] 
/// * [session] 
/// * [unbound] 
@BuiltValue()
abstract class WeChatExchangeResponse implements Built<WeChatExchangeResponse, WeChatExchangeResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'session')
  AuthSessionResponse? get session;

  @BuiltValueField(wireName: r'unbound')
  WeChatUnboundResponse? get unbound;

  WeChatExchangeResponse._();

  factory WeChatExchangeResponse([void updates(WeChatExchangeResponseBuilder b)]) = _$WeChatExchangeResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WeChatExchangeResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WeChatExchangeResponse> get serializer => _$WeChatExchangeResponseSerializer();
}

class _$WeChatExchangeResponseSerializer implements PrimitiveSerializer<WeChatExchangeResponse> {
  @override
  final Iterable<Type> types = const [WeChatExchangeResponse, _$WeChatExchangeResponse];

  @override
  final String wireName = r'WeChatExchangeResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WeChatExchangeResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    if (object.session != null) {
      yield r'session';
      yield serializers.serialize(
        object.session,
        specifiedType: const FullType.nullable(AuthSessionResponse),
      );
    }
    if (object.unbound != null) {
      yield r'unbound';
      yield serializers.serialize(
        object.unbound,
        specifiedType: const FullType.nullable(WeChatUnboundResponse),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WeChatExchangeResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WeChatExchangeResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'session':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(AuthSessionResponse),
          ) as AuthSessionResponse?;
          if (valueDes == null) continue;
          result.session.replace(valueDes);
          break;
        case r'unbound':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(WeChatUnboundResponse),
          ) as WeChatUnboundResponse?;
          if (valueDes == null) continue;
          result.unbound.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WeChatExchangeResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WeChatExchangeResponseBuilder();
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

