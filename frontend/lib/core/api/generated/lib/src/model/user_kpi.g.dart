// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_kpi.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserKPI extends UserKPI {
  @override
  final int crawlCountToday;
  @override
  final int matchCount;
  @override
  final int newJobsToday;
  @override
  final int priceDropsToday;
  @override
  final int totalProducts;

  factory _$UserKPI([void Function(UserKPIBuilder)? updates]) =>
      (UserKPIBuilder()..update(updates))._build();

  _$UserKPI._({
    required this.crawlCountToday,
    required this.matchCount,
    required this.newJobsToday,
    required this.priceDropsToday,
    required this.totalProducts,
  }) : super._();
  @override
  UserKPI rebuild(void Function(UserKPIBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserKPIBuilder toBuilder() => UserKPIBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserKPI &&
        crawlCountToday == other.crawlCountToday &&
        matchCount == other.matchCount &&
        newJobsToday == other.newJobsToday &&
        priceDropsToday == other.priceDropsToday &&
        totalProducts == other.totalProducts;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, crawlCountToday.hashCode);
    _$hash = $jc(_$hash, matchCount.hashCode);
    _$hash = $jc(_$hash, newJobsToday.hashCode);
    _$hash = $jc(_$hash, priceDropsToday.hashCode);
    _$hash = $jc(_$hash, totalProducts.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserKPI')
          ..add('crawlCountToday', crawlCountToday)
          ..add('matchCount', matchCount)
          ..add('newJobsToday', newJobsToday)
          ..add('priceDropsToday', priceDropsToday)
          ..add('totalProducts', totalProducts))
        .toString();
  }
}

class UserKPIBuilder implements Builder<UserKPI, UserKPIBuilder> {
  _$UserKPI? _$v;

  int? _crawlCountToday;
  int? get crawlCountToday => _$this._crawlCountToday;
  set crawlCountToday(int? crawlCountToday) =>
      _$this._crawlCountToday = crawlCountToday;

  int? _matchCount;
  int? get matchCount => _$this._matchCount;
  set matchCount(int? matchCount) => _$this._matchCount = matchCount;

  int? _newJobsToday;
  int? get newJobsToday => _$this._newJobsToday;
  set newJobsToday(int? newJobsToday) => _$this._newJobsToday = newJobsToday;

  int? _priceDropsToday;
  int? get priceDropsToday => _$this._priceDropsToday;
  set priceDropsToday(int? priceDropsToday) =>
      _$this._priceDropsToday = priceDropsToday;

  int? _totalProducts;
  int? get totalProducts => _$this._totalProducts;
  set totalProducts(int? totalProducts) =>
      _$this._totalProducts = totalProducts;

  UserKPIBuilder() {
    UserKPI._defaults(this);
  }

  UserKPIBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _crawlCountToday = $v.crawlCountToday;
      _matchCount = $v.matchCount;
      _newJobsToday = $v.newJobsToday;
      _priceDropsToday = $v.priceDropsToday;
      _totalProducts = $v.totalProducts;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserKPI other) {
    _$v = other as _$UserKPI;
  }

  @override
  void update(void Function(UserKPIBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserKPI build() => _build();

  _$UserKPI _build() {
    final _$result =
        _$v ??
        _$UserKPI._(
          crawlCountToday: BuiltValueNullFieldError.checkNotNull(
            crawlCountToday,
            r'UserKPI',
            'crawlCountToday',
          ),
          matchCount: BuiltValueNullFieldError.checkNotNull(
            matchCount,
            r'UserKPI',
            'matchCount',
          ),
          newJobsToday: BuiltValueNullFieldError.checkNotNull(
            newJobsToday,
            r'UserKPI',
            'newJobsToday',
          ),
          priceDropsToday: BuiltValueNullFieldError.checkNotNull(
            priceDropsToday,
            r'UserKPI',
            'priceDropsToday',
          ),
          totalProducts: BuiltValueNullFieldError.checkNotNull(
            totalProducts,
            r'UserKPI',
            'totalProducts',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
