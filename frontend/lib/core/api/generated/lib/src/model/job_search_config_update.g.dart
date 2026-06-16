// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_search_config_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const JobSearchConfigUpdatePlatformEnum
    _$jobSearchConfigUpdatePlatformEnum_boss =
    const JobSearchConfigUpdatePlatformEnum._('boss');
const JobSearchConfigUpdatePlatformEnum
    _$jobSearchConfigUpdatePlatformEnum_n51job =
    const JobSearchConfigUpdatePlatformEnum._('n51job');
const JobSearchConfigUpdatePlatformEnum
    _$jobSearchConfigUpdatePlatformEnum_liepin =
    const JobSearchConfigUpdatePlatformEnum._('liepin');

JobSearchConfigUpdatePlatformEnum _$jobSearchConfigUpdatePlatformEnumValueOf(
    String name) {
  switch (name) {
    case 'boss':
      return _$jobSearchConfigUpdatePlatformEnum_boss;
    case 'n51job':
      return _$jobSearchConfigUpdatePlatformEnum_n51job;
    case 'liepin':
      return _$jobSearchConfigUpdatePlatformEnum_liepin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<JobSearchConfigUpdatePlatformEnum>
    _$jobSearchConfigUpdatePlatformEnumValues = BuiltSet<
        JobSearchConfigUpdatePlatformEnum>(const <JobSearchConfigUpdatePlatformEnum>[
  _$jobSearchConfigUpdatePlatformEnum_boss,
  _$jobSearchConfigUpdatePlatformEnum_n51job,
  _$jobSearchConfigUpdatePlatformEnum_liepin,
]);

Serializer<JobSearchConfigUpdatePlatformEnum>
    _$jobSearchConfigUpdatePlatformEnumSerializer =
    _$JobSearchConfigUpdatePlatformEnumSerializer();

class _$JobSearchConfigUpdatePlatformEnumSerializer
    implements PrimitiveSerializer<JobSearchConfigUpdatePlatformEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'boss': 'boss',
    'n51job': '51job',
    'liepin': 'liepin',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'boss': 'boss',
    '51job': 'n51job',
    'liepin': 'liepin',
  };

  @override
  final Iterable<Type> types = const <Type>[JobSearchConfigUpdatePlatformEnum];
  @override
  final String wireName = 'JobSearchConfigUpdatePlatformEnum';

  @override
  Object serialize(
          Serializers serializers, JobSearchConfigUpdatePlatformEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  JobSearchConfigUpdatePlatformEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      JobSearchConfigUpdatePlatformEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$JobSearchConfigUpdate extends JobSearchConfigUpdate {
  @override
  final bool? active;
  @override
  final String? cityCode;
  @override
  final String? cronExpression;
  @override
  final String? cronTimezone;
  @override
  final int? deactivationThreshold;
  @override
  final String? education;
  @override
  final bool? enableMatchAnalysis;
  @override
  final String? experience;
  @override
  final String? keyword;
  @override
  final String? name;
  @override
  final bool? notifyOnNew;
  @override
  final JobSearchConfigUpdatePlatformEnum? platform;
  @override
  final String? profileKey;
  @override
  final int? salaryMax;
  @override
  final int? salaryMin;
  @override
  final String? url;

  factory _$JobSearchConfigUpdate(
          [void Function(JobSearchConfigUpdateBuilder)? updates]) =>
      (JobSearchConfigUpdateBuilder()..update(updates))._build();

  _$JobSearchConfigUpdate._(
      {this.active,
      this.cityCode,
      this.cronExpression,
      this.cronTimezone,
      this.deactivationThreshold,
      this.education,
      this.enableMatchAnalysis,
      this.experience,
      this.keyword,
      this.name,
      this.notifyOnNew,
      this.platform,
      this.profileKey,
      this.salaryMax,
      this.salaryMin,
      this.url})
      : super._();
  @override
  JobSearchConfigUpdate rebuild(
          void Function(JobSearchConfigUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobSearchConfigUpdateBuilder toBuilder() =>
      JobSearchConfigUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobSearchConfigUpdate &&
        active == other.active &&
        cityCode == other.cityCode &&
        cronExpression == other.cronExpression &&
        cronTimezone == other.cronTimezone &&
        deactivationThreshold == other.deactivationThreshold &&
        education == other.education &&
        enableMatchAnalysis == other.enableMatchAnalysis &&
        experience == other.experience &&
        keyword == other.keyword &&
        name == other.name &&
        notifyOnNew == other.notifyOnNew &&
        platform == other.platform &&
        profileKey == other.profileKey &&
        salaryMax == other.salaryMax &&
        salaryMin == other.salaryMin &&
        url == other.url;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, cityCode.hashCode);
    _$hash = $jc(_$hash, cronExpression.hashCode);
    _$hash = $jc(_$hash, cronTimezone.hashCode);
    _$hash = $jc(_$hash, deactivationThreshold.hashCode);
    _$hash = $jc(_$hash, education.hashCode);
    _$hash = $jc(_$hash, enableMatchAnalysis.hashCode);
    _$hash = $jc(_$hash, experience.hashCode);
    _$hash = $jc(_$hash, keyword.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, notifyOnNew.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jc(_$hash, salaryMax.hashCode);
    _$hash = $jc(_$hash, salaryMin.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JobSearchConfigUpdate')
          ..add('active', active)
          ..add('cityCode', cityCode)
          ..add('cronExpression', cronExpression)
          ..add('cronTimezone', cronTimezone)
          ..add('deactivationThreshold', deactivationThreshold)
          ..add('education', education)
          ..add('enableMatchAnalysis', enableMatchAnalysis)
          ..add('experience', experience)
          ..add('keyword', keyword)
          ..add('name', name)
          ..add('notifyOnNew', notifyOnNew)
          ..add('platform', platform)
          ..add('profileKey', profileKey)
          ..add('salaryMax', salaryMax)
          ..add('salaryMin', salaryMin)
          ..add('url', url))
        .toString();
  }
}

class JobSearchConfigUpdateBuilder
    implements Builder<JobSearchConfigUpdate, JobSearchConfigUpdateBuilder> {
  _$JobSearchConfigUpdate? _$v;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  String? _cityCode;
  String? get cityCode => _$this._cityCode;
  set cityCode(String? cityCode) => _$this._cityCode = cityCode;

  String? _cronExpression;
  String? get cronExpression => _$this._cronExpression;
  set cronExpression(String? cronExpression) =>
      _$this._cronExpression = cronExpression;

  String? _cronTimezone;
  String? get cronTimezone => _$this._cronTimezone;
  set cronTimezone(String? cronTimezone) => _$this._cronTimezone = cronTimezone;

  int? _deactivationThreshold;
  int? get deactivationThreshold => _$this._deactivationThreshold;
  set deactivationThreshold(int? deactivationThreshold) =>
      _$this._deactivationThreshold = deactivationThreshold;

  String? _education;
  String? get education => _$this._education;
  set education(String? education) => _$this._education = education;

  bool? _enableMatchAnalysis;
  bool? get enableMatchAnalysis => _$this._enableMatchAnalysis;
  set enableMatchAnalysis(bool? enableMatchAnalysis) =>
      _$this._enableMatchAnalysis = enableMatchAnalysis;

  String? _experience;
  String? get experience => _$this._experience;
  set experience(String? experience) => _$this._experience = experience;

  String? _keyword;
  String? get keyword => _$this._keyword;
  set keyword(String? keyword) => _$this._keyword = keyword;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  bool? _notifyOnNew;
  bool? get notifyOnNew => _$this._notifyOnNew;
  set notifyOnNew(bool? notifyOnNew) => _$this._notifyOnNew = notifyOnNew;

  JobSearchConfigUpdatePlatformEnum? _platform;
  JobSearchConfigUpdatePlatformEnum? get platform => _$this._platform;
  set platform(JobSearchConfigUpdatePlatformEnum? platform) =>
      _$this._platform = platform;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  int? _salaryMax;
  int? get salaryMax => _$this._salaryMax;
  set salaryMax(int? salaryMax) => _$this._salaryMax = salaryMax;

  int? _salaryMin;
  int? get salaryMin => _$this._salaryMin;
  set salaryMin(int? salaryMin) => _$this._salaryMin = salaryMin;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  JobSearchConfigUpdateBuilder() {
    JobSearchConfigUpdate._defaults(this);
  }

  JobSearchConfigUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _active = $v.active;
      _cityCode = $v.cityCode;
      _cronExpression = $v.cronExpression;
      _cronTimezone = $v.cronTimezone;
      _deactivationThreshold = $v.deactivationThreshold;
      _education = $v.education;
      _enableMatchAnalysis = $v.enableMatchAnalysis;
      _experience = $v.experience;
      _keyword = $v.keyword;
      _name = $v.name;
      _notifyOnNew = $v.notifyOnNew;
      _platform = $v.platform;
      _profileKey = $v.profileKey;
      _salaryMax = $v.salaryMax;
      _salaryMin = $v.salaryMin;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobSearchConfigUpdate other) {
    _$v = other as _$JobSearchConfigUpdate;
  }

  @override
  void update(void Function(JobSearchConfigUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobSearchConfigUpdate build() => _build();

  _$JobSearchConfigUpdate _build() {
    final _$result = _$v ??
        _$JobSearchConfigUpdate._(
          active: active,
          cityCode: cityCode,
          cronExpression: cronExpression,
          cronTimezone: cronTimezone,
          deactivationThreshold: deactivationThreshold,
          education: education,
          enableMatchAnalysis: enableMatchAnalysis,
          experience: experience,
          keyword: keyword,
          name: name,
          notifyOnNew: notifyOnNew,
          platform: platform,
          profileKey: profileKey,
          salaryMax: salaryMax,
          salaryMin: salaryMin,
          url: url,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
