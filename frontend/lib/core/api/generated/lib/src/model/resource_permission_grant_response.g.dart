// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_permission_grant_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResourcePermissionGrantResponse
    extends ResourcePermissionGrantResponse {
  @override
  final int granted;

  factory _$ResourcePermissionGrantResponse([
    void Function(ResourcePermissionGrantResponseBuilder)? updates,
  ]) => (ResourcePermissionGrantResponseBuilder()..update(updates))._build();

  _$ResourcePermissionGrantResponse._({required this.granted}) : super._();
  @override
  ResourcePermissionGrantResponse rebuild(
    void Function(ResourcePermissionGrantResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ResourcePermissionGrantResponseBuilder toBuilder() =>
      ResourcePermissionGrantResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResourcePermissionGrantResponse && granted == other.granted;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, granted.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ResourcePermissionGrantResponse',
    )..add('granted', granted)).toString();
  }
}

class ResourcePermissionGrantResponseBuilder
    implements
        Builder<
          ResourcePermissionGrantResponse,
          ResourcePermissionGrantResponseBuilder
        > {
  _$ResourcePermissionGrantResponse? _$v;

  int? _granted;
  int? get granted => _$this._granted;
  set granted(int? granted) => _$this._granted = granted;

  ResourcePermissionGrantResponseBuilder() {
    ResourcePermissionGrantResponse._defaults(this);
  }

  ResourcePermissionGrantResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _granted = $v.granted;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResourcePermissionGrantResponse other) {
    _$v = other as _$ResourcePermissionGrantResponse;
  }

  @override
  void update(void Function(ResourcePermissionGrantResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResourcePermissionGrantResponse build() => _build();

  _$ResourcePermissionGrantResponse _build() {
    final _$result =
        _$v ??
        _$ResourcePermissionGrantResponse._(
          granted: BuiltValueNullFieldError.checkNotNull(
            granted,
            r'ResourcePermissionGrantResponse',
            'granted',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
