//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mavra_api/src/model/role_permission_response.dart';
import 'package:mavra_api/src/model/permission_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'role_permission_matrix_response.g.dart';

/// Schema for the full role-permission matrix.
///
/// Properties:
/// * [allPermissions] 
/// * [roles] 
@BuiltValue()
abstract class RolePermissionMatrixResponse implements Built<RolePermissionMatrixResponse, RolePermissionMatrixResponseBuilder> {
  @BuiltValueField(wireName: r'all_permissions')
  BuiltList<PermissionResponse> get allPermissions;

  @BuiltValueField(wireName: r'roles')
  BuiltList<RolePermissionResponse> get roles;

  RolePermissionMatrixResponse._();

  factory RolePermissionMatrixResponse([void updates(RolePermissionMatrixResponseBuilder b)]) = _$RolePermissionMatrixResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RolePermissionMatrixResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RolePermissionMatrixResponse> get serializer => _$RolePermissionMatrixResponseSerializer();
}

class _$RolePermissionMatrixResponseSerializer implements PrimitiveSerializer<RolePermissionMatrixResponse> {
  @override
  final Iterable<Type> types = const [RolePermissionMatrixResponse, _$RolePermissionMatrixResponse];

  @override
  final String wireName = r'RolePermissionMatrixResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RolePermissionMatrixResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'all_permissions';
    yield serializers.serialize(
      object.allPermissions,
      specifiedType: const FullType(BuiltList, [FullType(PermissionResponse)]),
    );
    yield r'roles';
    yield serializers.serialize(
      object.roles,
      specifiedType: const FullType(BuiltList, [FullType(RolePermissionResponse)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RolePermissionMatrixResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RolePermissionMatrixResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'all_permissions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PermissionResponse)]),
          ) as BuiltList<PermissionResponse>;
          result.allPermissions.replace(valueDes);
          break;
        case r'roles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RolePermissionResponse)]),
          ) as BuiltList<RolePermissionResponse>;
          result.roles.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RolePermissionMatrixResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RolePermissionMatrixResponseBuilder();
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

