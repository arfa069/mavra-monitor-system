// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_auth_message_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AppSchemasAuthMessageResponse extends AppSchemasAuthMessageResponse {
  @override
  final String message;

  factory _$AppSchemasAuthMessageResponse([
    void Function(AppSchemasAuthMessageResponseBuilder)? updates,
  ]) => (AppSchemasAuthMessageResponseBuilder()..update(updates))._build();

  _$AppSchemasAuthMessageResponse._({required this.message}) : super._();
  @override
  AppSchemasAuthMessageResponse rebuild(
    void Function(AppSchemasAuthMessageResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AppSchemasAuthMessageResponseBuilder toBuilder() =>
      AppSchemasAuthMessageResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppSchemasAuthMessageResponse && message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'AppSchemasAuthMessageResponse',
    )..add('message', message)).toString();
  }
}

class AppSchemasAuthMessageResponseBuilder
    implements
        Builder<
          AppSchemasAuthMessageResponse,
          AppSchemasAuthMessageResponseBuilder
        > {
  _$AppSchemasAuthMessageResponse? _$v;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  AppSchemasAuthMessageResponseBuilder() {
    AppSchemasAuthMessageResponse._defaults(this);
  }

  AppSchemasAuthMessageResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppSchemasAuthMessageResponse other) {
    _$v = other as _$AppSchemasAuthMessageResponse;
  }

  @override
  void update(void Function(AppSchemasAuthMessageResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AppSchemasAuthMessageResponse build() => _build();

  _$AppSchemasAuthMessageResponse _build() {
    final _$result =
        _$v ??
        _$AppSchemasAuthMessageResponse._(
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'AppSchemasAuthMessageResponse',
            'message',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
