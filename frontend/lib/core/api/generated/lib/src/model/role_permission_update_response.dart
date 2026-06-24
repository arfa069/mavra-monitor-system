//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'role_permission_update_response.g.dart';

/// RolePermissionUpdateResponse
///
/// Properties:
/// * [permissions] 
/// * [role] 
@BuiltValue()
abstract class RolePermissionUpdateResponse implements Built<RolePermissionUpdateResponse, RolePermissionUpdateResponseBuilder> {
  @BuiltValueField(wireName: r'permissions')
  BuiltList<String> get permissions;

  @BuiltValueField(wireName: r'role')
  String get role;

  RolePermissionUpdateResponse._();

  factory RolePermissionUpdateResponse([void updates(RolePermissionUpdateResponseBuilder b)]) = _$RolePermissionUpdateResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RolePermissionUpdateResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RolePermissionUpdateResponse> get serializer => _$RolePermissionUpdateResponseSerializer();
}

class _$RolePermissionUpdateResponseSerializer implements PrimitiveSerializer<RolePermissionUpdateResponse> {
  @override
  final Iterable<Type> types = const [RolePermissionUpdateResponse, _$RolePermissionUpdateResponse];

  @override
  final String wireName = r'RolePermissionUpdateResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RolePermissionUpdateResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'permissions';
    yield serializers.serialize(
      object.permissions,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RolePermissionUpdateResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RolePermissionUpdateResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'permissions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.permissions.replace(valueDes);
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.role = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RolePermissionUpdateResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RolePermissionUpdateResponseBuilder();
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

