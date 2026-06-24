//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'dart:core';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/any_of.dart';

part 'threshold_percent1.g.dart';

/// ThresholdPercent1
@BuiltValue()
abstract class ThresholdPercent1 implements Built<ThresholdPercent1, ThresholdPercent1Builder> {
  /// Any Of [String], [num]
  AnyOf get anyOf;

  ThresholdPercent1._();

  factory ThresholdPercent1([void updates(ThresholdPercent1Builder b)]) = _$ThresholdPercent1;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ThresholdPercent1Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ThresholdPercent1> get serializer => _$ThresholdPercent1Serializer();
}

class _$ThresholdPercent1Serializer implements PrimitiveSerializer<ThresholdPercent1> {
  @override
  final Iterable<Type> types = const [ThresholdPercent1, _$ThresholdPercent1];

  @override
  final String wireName = r'ThresholdPercent1';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ThresholdPercent1 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
  }

  @override
  Object serialize(
    Serializers serializers,
    ThresholdPercent1 object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final anyOf = object.anyOf;
    return serializers.serialize(anyOf, specifiedType: FullType(AnyOf, anyOf.valueTypes.map((type) => FullType(type)).toList()))!;
  }

  @override
  ThresholdPercent1 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ThresholdPercent1Builder();
    Object? anyOfDataSrc;
    final targetType = const FullType(AnyOf, [FullType(num), FullType(String), ]);
    anyOfDataSrc = serialized;
    result.anyOf = serializers.deserialize(anyOfDataSrc, specifiedType: targetType) as AnyOf;
    return result.build();
  }
}

