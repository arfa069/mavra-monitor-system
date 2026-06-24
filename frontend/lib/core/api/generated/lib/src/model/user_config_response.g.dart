// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_config_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserConfigResponse extends UserConfigResponse {
  @override
  final int id;
  @override
  final String username;
  @override
  final DateTime? createdAt;
  @override
  final int? dataRetentionDays;
  @override
  final String? feishuWebhookUrl;
  @override
  final DateTime? updatedAt;

  factory _$UserConfigResponse([
    void Function(UserConfigResponseBuilder)? updates,
  ]) => (UserConfigResponseBuilder()..update(updates))._build();

  _$UserConfigResponse._({
    required this.id,
    required this.username,
    this.createdAt,
    this.dataRetentionDays,
    this.feishuWebhookUrl,
    this.updatedAt,
  }) : super._();
  @override
  UserConfigResponse rebuild(
    void Function(UserConfigResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UserConfigResponseBuilder toBuilder() =>
      UserConfigResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserConfigResponse &&
        id == other.id &&
        username == other.username &&
        createdAt == other.createdAt &&
        dataRetentionDays == other.dataRetentionDays &&
        feishuWebhookUrl == other.feishuWebhookUrl &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, dataRetentionDays.hashCode);
    _$hash = $jc(_$hash, feishuWebhookUrl.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserConfigResponse')
          ..add('id', id)
          ..add('username', username)
          ..add('createdAt', createdAt)
          ..add('dataRetentionDays', dataRetentionDays)
          ..add('feishuWebhookUrl', feishuWebhookUrl)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class UserConfigResponseBuilder
    implements Builder<UserConfigResponse, UserConfigResponseBuilder> {
  _$UserConfigResponse? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  int? _dataRetentionDays;
  int? get dataRetentionDays => _$this._dataRetentionDays;
  set dataRetentionDays(int? dataRetentionDays) =>
      _$this._dataRetentionDays = dataRetentionDays;

  String? _feishuWebhookUrl;
  String? get feishuWebhookUrl => _$this._feishuWebhookUrl;
  set feishuWebhookUrl(String? feishuWebhookUrl) =>
      _$this._feishuWebhookUrl = feishuWebhookUrl;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  UserConfigResponseBuilder() {
    UserConfigResponse._defaults(this);
  }

  UserConfigResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _username = $v.username;
      _createdAt = $v.createdAt;
      _dataRetentionDays = $v.dataRetentionDays;
      _feishuWebhookUrl = $v.feishuWebhookUrl;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserConfigResponse other) {
    _$v = other as _$UserConfigResponse;
  }

  @override
  void update(void Function(UserConfigResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserConfigResponse build() => _build();

  _$UserConfigResponse _build() {
    final _$result =
        _$v ??
        _$UserConfigResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'UserConfigResponse',
            'id',
          ),
          username: BuiltValueNullFieldError.checkNotNull(
            username,
            r'UserConfigResponse',
            'username',
          ),
          createdAt: createdAt,
          dataRetentionDays: dataRetentionDays,
          feishuWebhookUrl: feishuWebhookUrl,
          updatedAt: updatedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
