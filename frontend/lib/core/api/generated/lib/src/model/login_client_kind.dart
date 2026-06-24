//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'login_client_kind.g.dart';

class LoginClientKind extends EnumClass {

  /// Client storage mode for token delivery.
  @BuiltValueEnumConst(wireName: r'web')
  static const LoginClientKind web = _$web;
  /// Client storage mode for token delivery.
  @BuiltValueEnumConst(wireName: r'native')
  static const LoginClientKind native_ = _$native_;

  static Serializer<LoginClientKind> get serializer => _$loginClientKindSerializer;

  const LoginClientKind._(String name): super(name);

  static BuiltSet<LoginClientKind> get values => _$values;
  static LoginClientKind valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class LoginClientKindMixin implements _$LoginClientKindMixin {}

