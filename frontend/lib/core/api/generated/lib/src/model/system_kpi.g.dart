// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_kpi.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SystemKPI extends SystemKPI {
  @override
  final int activeAlerts;
  @override
  final num diskUsage;
  @override
  final num memoryUsage;
  @override
  final num successRate;
  @override
  final int totalCrawls;
  @override
  final int totalUsers;

  factory _$SystemKPI([void Function(SystemKPIBuilder)? updates]) =>
      (SystemKPIBuilder()..update(updates))._build();

  _$SystemKPI._({
    required this.activeAlerts,
    required this.diskUsage,
    required this.memoryUsage,
    required this.successRate,
    required this.totalCrawls,
    required this.totalUsers,
  }) : super._();
  @override
  SystemKPI rebuild(void Function(SystemKPIBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SystemKPIBuilder toBuilder() => SystemKPIBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SystemKPI &&
        activeAlerts == other.activeAlerts &&
        diskUsage == other.diskUsage &&
        memoryUsage == other.memoryUsage &&
        successRate == other.successRate &&
        totalCrawls == other.totalCrawls &&
        totalUsers == other.totalUsers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, activeAlerts.hashCode);
    _$hash = $jc(_$hash, diskUsage.hashCode);
    _$hash = $jc(_$hash, memoryUsage.hashCode);
    _$hash = $jc(_$hash, successRate.hashCode);
    _$hash = $jc(_$hash, totalCrawls.hashCode);
    _$hash = $jc(_$hash, totalUsers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SystemKPI')
          ..add('activeAlerts', activeAlerts)
          ..add('diskUsage', diskUsage)
          ..add('memoryUsage', memoryUsage)
          ..add('successRate', successRate)
          ..add('totalCrawls', totalCrawls)
          ..add('totalUsers', totalUsers))
        .toString();
  }
}

class SystemKPIBuilder implements Builder<SystemKPI, SystemKPIBuilder> {
  _$SystemKPI? _$v;

  int? _activeAlerts;
  int? get activeAlerts => _$this._activeAlerts;
  set activeAlerts(int? activeAlerts) => _$this._activeAlerts = activeAlerts;

  num? _diskUsage;
  num? get diskUsage => _$this._diskUsage;
  set diskUsage(num? diskUsage) => _$this._diskUsage = diskUsage;

  num? _memoryUsage;
  num? get memoryUsage => _$this._memoryUsage;
  set memoryUsage(num? memoryUsage) => _$this._memoryUsage = memoryUsage;

  num? _successRate;
  num? get successRate => _$this._successRate;
  set successRate(num? successRate) => _$this._successRate = successRate;

  int? _totalCrawls;
  int? get totalCrawls => _$this._totalCrawls;
  set totalCrawls(int? totalCrawls) => _$this._totalCrawls = totalCrawls;

  int? _totalUsers;
  int? get totalUsers => _$this._totalUsers;
  set totalUsers(int? totalUsers) => _$this._totalUsers = totalUsers;

  SystemKPIBuilder() {
    SystemKPI._defaults(this);
  }

  SystemKPIBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _activeAlerts = $v.activeAlerts;
      _diskUsage = $v.diskUsage;
      _memoryUsage = $v.memoryUsage;
      _successRate = $v.successRate;
      _totalCrawls = $v.totalCrawls;
      _totalUsers = $v.totalUsers;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SystemKPI other) {
    _$v = other as _$SystemKPI;
  }

  @override
  void update(void Function(SystemKPIBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SystemKPI build() => _build();

  _$SystemKPI _build() {
    final _$result =
        _$v ??
        _$SystemKPI._(
          activeAlerts: BuiltValueNullFieldError.checkNotNull(
            activeAlerts,
            r'SystemKPI',
            'activeAlerts',
          ),
          diskUsage: BuiltValueNullFieldError.checkNotNull(
            diskUsage,
            r'SystemKPI',
            'diskUsage',
          ),
          memoryUsage: BuiltValueNullFieldError.checkNotNull(
            memoryUsage,
            r'SystemKPI',
            'memoryUsage',
          ),
          successRate: BuiltValueNullFieldError.checkNotNull(
            successRate,
            r'SystemKPI',
            'successRate',
          ),
          totalCrawls: BuiltValueNullFieldError.checkNotNull(
            totalCrawls,
            r'SystemKPI',
            'totalCrawls',
          ),
          totalUsers: BuiltValueNullFieldError.checkNotNull(
            totalUsers,
            r'SystemKPI',
            'totalUsers',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
