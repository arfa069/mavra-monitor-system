//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'dart:core';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/any_of.dart';

part 'threshold_percent.g.dart';

/// Trigger threshold percentage
@BuiltValue()
abstract class ThresholdPercent implements Built<ThresholdPercent, ThresholdPercentBuilder> {
  /// Any Of [String], [num]
  AnyOf get anyOf;

  ThresholdPercent._();

  factory ThresholdPercent([void updates(ThresholdPercentBuilder b)]) = _$ThresholdPercent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ThresholdPercentBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ThresholdPercent> get serializer => _$ThresholdPercentSerializer();
}

class _$ThresholdPercentSerializer implements PrimitiveSerializer<ThresholdPercent> {
  @override
  final Iterable<Type> types = const [ThresholdPercent, _$ThresholdPercent];

  @override
  final String wireName = r'ThresholdPercent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ThresholdPercent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
  }

  @override
  Object serialize(
    Serializers serializers,
    ThresholdPercent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final anyOf = object.anyOf;
    return serializers.serialize(anyOf, specifiedType: FullType(AnyOf, anyOf.valueTypes.map((type) => FullType(type)).toList()))!;
  }

  @override
  ThresholdPercent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ThresholdPercentBuilder();
    Object? anyOfDataSrc;
    final targetType = const FullType(AnyOf, [FullType(num), FullType(String), ]);
    anyOfDataSrc = serialized;
    result.anyOf = serializers.deserialize(anyOfDataSrc, specifiedType: targetType) as AnyOf;
    return result.build();
  }
}

