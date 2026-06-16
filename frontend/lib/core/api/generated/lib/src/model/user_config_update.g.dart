// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_config_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserConfigUpdate extends UserConfigUpdate {
  @override
  final int? dataRetentionDays;
  @override
  final String? feishuWebhookUrl;

  factory _$UserConfigUpdate(
          [void Function(UserConfigUpdateBuilder)? updates]) =>
      (UserConfigUpdateBuilder()..update(updates))._build();

  _$UserConfigUpdate._({this.dataRetentionDays, this.feishuWebhookUrl})
      : super._();
  @override
  UserConfigUpdate rebuild(void Function(UserConfigUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserConfigUpdateBuilder toBuilder() =>
      UserConfigUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserConfigUpdate &&
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
    return (newBuiltValueToStringHelper(r'UserConfigUpdate')
          ..add('dataRetentionDays', dataRetentionDays)
          ..add('feishuWebhookUrl', feishuWebhookUrl))
        .toString();
  }
}

class UserConfigUpdateBuilder
    implements Builder<UserConfigUpdate, UserConfigUpdateBuilder> {
  _$UserConfigUpdate? _$v;

  int? _dataRetentionDays;
  int? get dataRetentionDays => _$this._dataRetentionDays;
  set dataRetentionDays(int? dataRetentionDays) =>
      _$this._dataRetentionDays = dataRetentionDays;

  String? _feishuWebhookUrl;
  String? get feishuWebhookUrl => _$this._feishuWebhookUrl;
  set feishuWebhookUrl(String? feishuWebhookUrl) =>
      _$this._feishuWebhookUrl = feishuWebhookUrl;

  UserConfigUpdateBuilder() {
    UserConfigUpdate._defaults(this);
  }

  UserConfigUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _dataRetentionDays = $v.dataRetentionDays;
      _feishuWebhookUrl = $v.feishuWebhookUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserConfigUpdate other) {
    _$v = other as _$UserConfigUpdate;
  }

  @override
  void update(void Function(UserConfigUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserConfigUpdate build() => _build();

  _$UserConfigUpdate _build() {
    final _$result = _$v ??
        _$UserConfigUpdate._(
          dataRetentionDays: dataRetentionDays,
          feishuWebhookUrl: feishuWebhookUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
