// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_kpi_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DashboardKPIResponse extends DashboardKPIResponse {
  @override
  final UserKPI user;
  @override
  final SystemKPI? system;

  factory _$DashboardKPIResponse([
    void Function(DashboardKPIResponseBuilder)? updates,
  ]) => (DashboardKPIResponseBuilder()..update(updates))._build();

  _$DashboardKPIResponse._({required this.user, this.system}) : super._();
  @override
  DashboardKPIResponse rebuild(
    void Function(DashboardKPIResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DashboardKPIResponseBuilder toBuilder() =>
      DashboardKPIResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DashboardKPIResponse &&
        user == other.user &&
        system == other.system;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jc(_$hash, system.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DashboardKPIResponse')
          ..add('user', user)
          ..add('system', system))
        .toString();
  }
}

class DashboardKPIResponseBuilder
    implements Builder<DashboardKPIResponse, DashboardKPIResponseBuilder> {
  _$DashboardKPIResponse? _$v;

  UserKPIBuilder? _user;
  UserKPIBuilder get user => _$this._user ??= UserKPIBuilder();
  set user(UserKPIBuilder? user) => _$this._user = user;

  SystemKPIBuilder? _system;
  SystemKPIBuilder get system => _$this._system ??= SystemKPIBuilder();
  set system(SystemKPIBuilder? system) => _$this._system = system;

  DashboardKPIResponseBuilder() {
    DashboardKPIResponse._defaults(this);
  }

  DashboardKPIResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _user = $v.user.toBuilder();
      _system = $v.system?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DashboardKPIResponse other) {
    _$v = other as _$DashboardKPIResponse;
  }

  @override
  void update(void Function(DashboardKPIResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DashboardKPIResponse build() => _build();

  _$DashboardKPIResponse _build() {
    _$DashboardKPIResponse _$result;
    try {
      _$result =
          _$v ??
          _$DashboardKPIResponse._(
            user: user.build(),
            system: _system?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'user';
        user.build();
        _$failedField = 'system';
        _system?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DashboardKPIResponse',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
