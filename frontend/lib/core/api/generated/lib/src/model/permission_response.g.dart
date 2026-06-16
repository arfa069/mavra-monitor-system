// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PermissionResponse extends PermissionResponse {
  @override
  final String name;
  @override
  final String? description;

  factory _$PermissionResponse(
          [void Function(PermissionResponseBuilder)? updates]) =>
      (PermissionResponseBuilder()..update(updates))._build();

  _$PermissionResponse._({required this.name, this.description}) : super._();
  @override
  PermissionResponse rebuild(
          void Function(PermissionResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PermissionResponseBuilder toBuilder() =>
      PermissionResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PermissionResponse &&
        name == other.name &&
        description == other.description;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PermissionResponse')
          ..add('name', name)
          ..add('description', description))
        .toString();
  }
}

class PermissionResponseBuilder
    implements Builder<PermissionResponse, PermissionResponseBuilder> {
  _$PermissionResponse? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  PermissionResponseBuilder() {
    PermissionResponse._defaults(this);
  }

  PermissionResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _description = $v.description;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PermissionResponse other) {
    _$v = other as _$PermissionResponse;
  }

  @override
  void update(void Function(PermissionResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PermissionResponse build() => _build();

  _$PermissionResponse _build() {
    final _$result = _$v ??
        _$PermissionResponse._(
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'PermissionResponse', 'name'),
          description: description,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
