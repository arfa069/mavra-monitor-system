//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resource_permission_grant_response.g.dart';

/// ResourcePermissionGrantResponse
///
/// Properties:
/// * [granted] 
@BuiltValue()
abstract class ResourcePermissionGrantResponse implements Built<ResourcePermissionGrantResponse, ResourcePermissionGrantResponseBuilder> {
  @BuiltValueField(wireName: r'granted')
  int get granted;

  ResourcePermissionGrantResponse._();

  factory ResourcePermissionGrantResponse([void updates(ResourcePermissionGrantResponseBuilder b)]) = _$ResourcePermissionGrantResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResourcePermissionGrantResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResourcePermissionGrantResponse> get serializer => _$ResourcePermissionGrantResponseSerializer();
}

class _$ResourcePermissionGrantResponseSerializer implements PrimitiveSerializer<ResourcePermissionGrantResponse> {
  @override
  final Iterable<Type> types = const [ResourcePermissionGrantResponse, _$ResourcePermissionGrantResponse];

  @override
  final String wireName = r'ResourcePermissionGrantResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResourcePermissionGrantResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'granted';
    yield serializers.serialize(
      object.granted,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResourcePermissionGrantResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResourcePermissionGrantResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'granted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.granted = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResourcePermissionGrantResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResourcePermissionGrantResponseBuilder();
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

