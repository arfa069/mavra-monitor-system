// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_search_config_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const JobSearchConfigResponsePlatformEnum
_$jobSearchConfigResponsePlatformEnum_boss =
    const JobSearchConfigResponsePlatformEnum._('boss');
const JobSearchConfigResponsePlatformEnum
_$jobSearchConfigResponsePlatformEnum_n51job =
    const JobSearchConfigResponsePlatformEnum._('n51job');
const JobSearchConfigResponsePlatformEnum
_$jobSearchConfigResponsePlatformEnum_liepin =
    const JobSearchConfigResponsePlatformEnum._('liepin');

JobSearchConfigResponsePlatformEnum
_$jobSearchConfigResponsePlatformEnumValueOf(String name) {
  switch (name) {
    case 'boss':
      return _$jobSearchConfigResponsePlatformEnum_boss;
    case 'n51job':
      return _$jobSearchConfigResponsePlatformEnum_n51job;
    case 'liepin':
      return _$jobSearchConfigResponsePlatformEnum_liepin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<JobSearchConfigResponsePlatformEnum>
_$jobSearchConfigResponsePlatformEnumValues =
    BuiltSet<JobSearchConfigResponsePlatformEnum>(
      const <JobSearchConfigResponsePlatformEnum>[
        _$jobSearchConfigResponsePlatformEnum_boss,
        _$jobSearchConfigResponsePlatformEnum_n51job,
        _$jobSearchConfigResponsePlatformEnum_liepin,
      ],
    );

Serializer<JobSearchConfigResponsePlatformEnum>
_$jobSearchConfigResponsePlatformEnumSerializer =
    _$JobSearchConfigResponsePlatformEnumSerializer();

class _$JobSearchConfigResponsePlatformEnumSerializer
    implements PrimitiveSerializer<JobSearchConfigResponsePlatformEnum> {
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
  final Iterable<Type> types = const <Type>[
    JobSearchConfigResponsePlatformEnum,
  ];
  @override
  final String wireName = 'JobSearchConfigResponsePlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    JobSearchConfigResponsePlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  JobSearchConfigResponsePlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => JobSearchConfigResponsePlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$JobSearchConfigResponse extends JobSearchConfigResponse {
  @override
  final bool active;
  @override
  final String? cityCode;
  @override
  final DateTime createdAt;
  @override
  final String? cronExpression;
  @override
  final String? cronTimezone;
  @override
  final int deactivationThreshold;
  @override
  final String? education;
  @override
  final bool enableMatchAnalysis;
  @override
  final String? experience;
  @override
  final int id;
  @override
  final String? keyword;
  @override
  final String name;
  @override
  final bool notifyOnNew;
  @override
  final String profileKey;
  @override
  final int? salaryMax;
  @override
  final int? salaryMin;
  @override
  final DateTime updatedAt;
  @override
  final String url;
  @override
  final int userId;
  @override
  final JobSearchConfigResponsePlatformEnum? platform;

  factory _$JobSearchConfigResponse([
    void Function(JobSearchConfigResponseBuilder)? updates,
  ]) => (JobSearchConfigResponseBuilder()..update(updates))._build();

  _$JobSearchConfigResponse._({
    required this.active,
    this.cityCode,
    required this.createdAt,
    this.cronExpression,
    this.cronTimezone,
    required this.deactivationThreshold,
    this.education,
    required this.enableMatchAnalysis,
    this.experience,
    required this.id,
    this.keyword,
    required this.name,
    required this.notifyOnNew,
    required this.profileKey,
    this.salaryMax,
    this.salaryMin,
    required this.updatedAt,
    required this.url,
    required this.userId,
    this.platform,
  }) : super._();
  @override
  JobSearchConfigResponse rebuild(
    void Function(JobSearchConfigResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  JobSearchConfigResponseBuilder toBuilder() =>
      JobSearchConfigResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobSearchConfigResponse &&
        active == other.active &&
        cityCode == other.cityCode &&
        createdAt == other.createdAt &&
        cronExpression == other.cronExpression &&
        cronTimezone == other.cronTimezone &&
        deactivationThreshold == other.deactivationThreshold &&
        education == other.education &&
        enableMatchAnalysis == other.enableMatchAnalysis &&
        experience == other.experience &&
        id == other.id &&
        keyword == other.keyword &&
        name == other.name &&
        notifyOnNew == other.notifyOnNew &&
        profileKey == other.profileKey &&
        salaryMax == other.salaryMax &&
        salaryMin == other.salaryMin &&
        updatedAt == other.updatedAt &&
        url == other.url &&
        userId == other.userId &&
        platform == other.platform;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, cityCode.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, cronExpression.hashCode);
    _$hash = $jc(_$hash, cronTimezone.hashCode);
    _$hash = $jc(_$hash, deactivationThreshold.hashCode);
    _$hash = $jc(_$hash, education.hashCode);
    _$hash = $jc(_$hash, enableMatchAnalysis.hashCode);
    _$hash = $jc(_$hash, experience.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, keyword.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, notifyOnNew.hashCode);
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jc(_$hash, salaryMax.hashCode);
    _$hash = $jc(_$hash, salaryMin.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JobSearchConfigResponse')
          ..add('active', active)
          ..add('cityCode', cityCode)
          ..add('createdAt', createdAt)
          ..add('cronExpression', cronExpression)
          ..add('cronTimezone', cronTimezone)
          ..add('deactivationThreshold', deactivationThreshold)
          ..add('education', education)
          ..add('enableMatchAnalysis', enableMatchAnalysis)
          ..add('experience', experience)
          ..add('id', id)
          ..add('keyword', keyword)
          ..add('name', name)
          ..add('notifyOnNew', notifyOnNew)
          ..add('profileKey', profileKey)
          ..add('salaryMax', salaryMax)
          ..add('salaryMin', salaryMin)
          ..add('updatedAt', updatedAt)
          ..add('url', url)
          ..add('userId', userId)
          ..add('platform', platform))
        .toString();
  }
}

class JobSearchConfigResponseBuilder
    implements
        Builder<JobSearchConfigResponse, JobSearchConfigResponseBuilder> {
  _$JobSearchConfigResponse? _$v;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  String? _cityCode;
  String? get cityCode => _$this._cityCode;
  set cityCode(String? cityCode) => _$this._cityCode = cityCode;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

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

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _keyword;
  String? get keyword => _$this._keyword;
  set keyword(String? keyword) => _$this._keyword = keyword;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  bool? _notifyOnNew;
  bool? get notifyOnNew => _$this._notifyOnNew;
  set notifyOnNew(bool? notifyOnNew) => _$this._notifyOnNew = notifyOnNew;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  int? _salaryMax;
  int? get salaryMax => _$this._salaryMax;
  set salaryMax(int? salaryMax) => _$this._salaryMax = salaryMax;

  int? _salaryMin;
  int? get salaryMin => _$this._salaryMin;
  set salaryMin(int? salaryMin) => _$this._salaryMin = salaryMin;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  JobSearchConfigResponsePlatformEnum? _platform;
  JobSearchConfigResponsePlatformEnum? get platform => _$this._platform;
  set platform(JobSearchConfigResponsePlatformEnum? platform) =>
      _$this._platform = platform;

  JobSearchConfigResponseBuilder() {
    JobSearchConfigResponse._defaults(this);
  }

  JobSearchConfigResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _active = $v.active;
      _cityCode = $v.cityCode;
      _createdAt = $v.createdAt;
      _cronExpression = $v.cronExpression;
      _cronTimezone = $v.cronTimezone;
      _deactivationThreshold = $v.deactivationThreshold;
      _education = $v.education;
      _enableMatchAnalysis = $v.enableMatchAnalysis;
      _experience = $v.experience;
      _id = $v.id;
      _keyword = $v.keyword;
      _name = $v.name;
      _notifyOnNew = $v.notifyOnNew;
      _profileKey = $v.profileKey;
      _salaryMax = $v.salaryMax;
      _salaryMin = $v.salaryMin;
      _updatedAt = $v.updatedAt;
      _url = $v.url;
      _userId = $v.userId;
      _platform = $v.platform;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobSearchConfigResponse other) {
    _$v = other as _$JobSearchConfigResponse;
  }

  @override
  void update(void Function(JobSearchConfigResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobSearchConfigResponse build() => _build();

  _$JobSearchConfigResponse _build() {
    final _$result =
        _$v ??
        _$JobSearchConfigResponse._(
          active: BuiltValueNullFieldError.checkNotNull(
            active,
            r'JobSearchConfigResponse',
            'active',
          ),
          cityCode: cityCode,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'JobSearchConfigResponse',
            'createdAt',
          ),
          cronExpression: cronExpression,
          cronTimezone: cronTimezone,
          deactivationThreshold: BuiltValueNullFieldError.checkNotNull(
            deactivationThreshold,
            r'JobSearchConfigResponse',
            'deactivationThreshold',
          ),
          education: education,
          enableMatchAnalysis: BuiltValueNullFieldError.checkNotNull(
            enableMatchAnalysis,
            r'JobSearchConfigResponse',
            'enableMatchAnalysis',
          ),
          experience: experience,
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'JobSearchConfigResponse',
            'id',
          ),
          keyword: keyword,
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'JobSearchConfigResponse',
            'name',
          ),
          notifyOnNew: BuiltValueNullFieldError.checkNotNull(
            notifyOnNew,
            r'JobSearchConfigResponse',
            'notifyOnNew',
          ),
          profileKey: BuiltValueNullFieldError.checkNotNull(
            profileKey,
            r'JobSearchConfigResponse',
            'profileKey',
          ),
          salaryMax: salaryMax,
          salaryMin: salaryMin,
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'JobSearchConfigResponse',
            'updatedAt',
          ),
          url: BuiltValueNullFieldError.checkNotNull(
            url,
            r'JobSearchConfigResponse',
            'url',
          ),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'JobSearchConfigResponse',
            'userId',
          ),
          platform: platform,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
