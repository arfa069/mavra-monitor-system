//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/system_kpi.dart';
import 'package:mavra_api/src/model/user_kpi.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'dashboard_kpi_response.g.dart';

/// Combined KPI response for dashboard.
///
/// Properties:
/// * [user] 
/// * [system] 
@BuiltValue()
abstract class DashboardKPIResponse implements Built<DashboardKPIResponse, DashboardKPIResponseBuilder> {
  @BuiltValueField(wireName: r'user')
  UserKPI get user;

  @BuiltValueField(wireName: r'system')
  SystemKPI? get system;

  DashboardKPIResponse._();

  factory DashboardKPIResponse([void updates(DashboardKPIResponseBuilder b)]) = _$DashboardKPIResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DashboardKPIResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DashboardKPIResponse> get serializer => _$DashboardKPIResponseSerializer();
}

class _$DashboardKPIResponseSerializer implements PrimitiveSerializer<DashboardKPIResponse> {
  @override
  final Iterable<Type> types = const [DashboardKPIResponse, _$DashboardKPIResponse];

  @override
  final String wireName = r'DashboardKPIResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DashboardKPIResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'user';
    yield serializers.serialize(
      object.user,
      specifiedType: const FullType(UserKPI),
    );
    if (object.system != null) {
      yield r'system';
      yield serializers.serialize(
        object.system,
        specifiedType: const FullType.nullable(SystemKPI),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DashboardKPIResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DashboardKPIResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserKPI),
          ) as UserKPI;
          result.user.replace(valueDes);
          break;
        case r'system':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(SystemKPI),
          ) as SystemKPI?;
          if (valueDes == null) continue;
          result.system.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DashboardKPIResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DashboardKPIResponseBuilder();
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

