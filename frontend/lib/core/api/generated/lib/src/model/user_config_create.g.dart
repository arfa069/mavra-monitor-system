// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_config_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserConfigCreate extends UserConfigCreate {
  @override
  final int? dataRetentionDays;
  @override
  final String? feishuWebhookUrl;

  factory _$UserConfigCreate(
          [void Function(UserConfigCreateBuilder)? updates]) =>
      (UserConfigCreateBuilder()..update(updates))._build();

  _$UserConfigCreate._({this.dataRetentionDays, this.feishuWebhookUrl})
      : super._();
  @override
  UserConfigCreate rebuild(void Function(UserConfigCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserConfigCreateBuilder toBuilder() =>
      UserConfigCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserConfigCreate &&
        dataRetentionDays == other.dataRetentionDays &&
        feishuWebhookUrl == other.feishuWebhookUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, dataRetentionDays.hashCode);
    _$hash = $jc(_$hash, feishuWebhookUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserConfigCreate')
          ..add('dataRetentionDays', dataRetentionDays)
          ..add('feishuWebhookUrl', feishuWebhookUrl))
        .toString();
  }
}

class UserConfigCreateBuilder
    implements Builder<UserConfigCreate, UserConfigCreateBuilder> {
  _$UserConfigCreate? _$v;

  int? _dataRetentionDays;
  int? get dataRetentionDays => _$this._dataRetentionDays;
  set dataRetentionDays(int? dataRetentionDays) =>
      _$this._dataRetentionDays = dataRetentionDays;

  String? _feishuWebhookUrl;
  String? get feishuWebhookUrl => _$this._feishuWebhookUrl;
  set feishuWebhookUrl(String? feishuWebhookUrl) =>
      _$this._feishuWebhookUrl = feishuWebhookUrl;

  UserConfigCreateBuilder() {
    UserConfigCreate._defaults(this);
  }

  UserConfigCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _dataRetentionDays = $v.dataRetentionDays;
      _feishuWebhookUrl = $v.feishuWebhookUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserConfigCreate other) {
    _$v = other as _$UserConfigCreate;
  }

  @override
  void update(void Function(UserConfigCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserConfigCreate build() => _build();

  _$UserConfigCreate _build() {
    final _$result = _$v ??
        _$UserConfigCreate._(
          dataRetentionDays: dataRetentionDays,
          feishuWebhookUrl: feishuWebhookUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
