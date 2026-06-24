//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'system_kpi.g.dart';

/// System-level KPI metrics (admin only).
///
/// Properties:
/// * [activeAlerts] 
/// * [diskUsage] 
/// * [memoryUsage] 
/// * [successRate] 
/// * [totalCrawls] 
/// * [totalUsers] 
@BuiltValue()
abstract class SystemKPI implements Built<SystemKPI, SystemKPIBuilder> {
  @BuiltValueField(wireName: r'active_alerts')
  int get activeAlerts;

  @BuiltValueField(wireName: r'disk_usage')
  num get diskUsage;

  @BuiltValueField(wireName: r'memory_usage')
  num get memoryUsage;

  @BuiltValueField(wireName: r'success_rate')
  num get successRate;

  @BuiltValueField(wireName: r'total_crawls')
  int get totalCrawls;

  @BuiltValueField(wireName: r'total_users')
  int get totalUsers;

  SystemKPI._();

  factory SystemKPI([void updates(SystemKPIBuilder b)]) = _$SystemKPI;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SystemKPIBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SystemKPI> get serializer => _$SystemKPISerializer();
}

class _$SystemKPISerializer implements PrimitiveSerializer<SystemKPI> {
  @override
  final Iterable<Type> types = const [SystemKPI, _$SystemKPI];

  @override
  final String wireName = r'SystemKPI';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SystemKPI object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'active_alerts';
    yield serializers.serialize(
      object.activeAlerts,
      specifiedType: const FullType(int),
    );
    yield r'disk_usage';
    yield serializers.serialize(
      object.diskUsage,
      specifiedType: const FullType(num),
    );
    yield r'memory_usage';
    yield serializers.serialize(
      object.memoryUsage,
      specifiedType: const FullType(num),
    );
    yield r'success_rate';
    yield serializers.serialize(
      object.successRate,
      specifiedType: const FullType(num),
    );
    yield r'total_crawls';
    yield serializers.serialize(
      object.totalCrawls,
      specifiedType: const FullType(int),
    );
    yield r'total_users';
    yield serializers.serialize(
      object.totalUsers,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SystemKPI object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SystemKPIBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'active_alerts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.activeAlerts = valueDes;
          break;
        case r'disk_usage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.diskUsage = valueDes;
          break;
        case r'memory_usage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.memoryUsage = valueDes;
          break;
        case r'success_rate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.successRate = valueDes;
          break;
        case r'total_crawls':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalCrawls = valueDes;
          break;
        case r'total_users':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalUsers = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SystemKPI deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SystemKPIBuilder();
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

