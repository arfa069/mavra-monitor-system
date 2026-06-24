// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_client_kind.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const LoginClientKind _$web = const LoginClientKind._('web');
const LoginClientKind _$native_ = const LoginClientKind._('native_');

LoginClientKind _$valueOf(String name) {
  switch (name) {
    case 'web':
      return _$web;
    case 'native_':
      return _$native_;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<LoginClientKind> _$values = BuiltSet<LoginClientKind>(
  const <LoginClientKind>[_$web, _$native_],
);

class _$LoginClientKindMeta {
  const _$LoginClientKindMeta();
  LoginClientKind get web => _$web;
  LoginClientKind get native_ => _$native_;
  LoginClientKind valueOf(String name) => _$valueOf(name);
  BuiltSet<LoginClientKind> get values => _$values;
}

mixin _$LoginClientKindMixin {
  // ignore: non_constant_identifier_names
  _$LoginClientKindMeta get LoginClientKind => const _$LoginClientKindMeta();
}

Serializer<LoginClientKind> _$loginClientKindSerializer =
    _$LoginClientKindSerializer();

class _$LoginClientKindSerializer
    implements PrimitiveSerializer<LoginClientKind> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'web': 'web',
    'native_': 'native',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'web': 'web',
    'native': 'native_',
  };

  @override
  final Iterable<Type> types = const <Type>[LoginClientKind];
  @override
  final String wireName = 'LoginClientKind';

  @override
  Object serialize(
    Serializers serializers,
    LoginClientKind object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  LoginClientKind deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => LoginClientKind.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
