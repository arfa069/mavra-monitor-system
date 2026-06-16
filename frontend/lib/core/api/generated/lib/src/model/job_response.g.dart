// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const JobResponsePlatformEnum _$jobResponsePlatformEnum_boss =
    const JobResponsePlatformEnum._('boss');
const JobResponsePlatformEnum _$jobResponsePlatformEnum_n51job =
    const JobResponsePlatformEnum._('n51job');
const JobResponsePlatformEnum _$jobResponsePlatformEnum_liepin =
    const JobResponsePlatformEnum._('liepin');

JobResponsePlatformEnum _$jobResponsePlatformEnumValueOf(String name) {
  switch (name) {
    case 'boss':
      return _$jobResponsePlatformEnum_boss;
    case 'n51job':
      return _$jobResponsePlatformEnum_n51job;
    case 'liepin':
      return _$jobResponsePlatformEnum_liepin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<JobResponsePlatformEnum> _$jobResponsePlatformEnumValues =
    BuiltSet<JobResponsePlatformEnum>(const <JobResponsePlatformEnum>[
      _$jobResponsePlatformEnum_boss,
      _$jobResponsePlatformEnum_n51job,
      _$jobResponsePlatformEnum_liepin,
    ]);

Serializer<JobResponsePlatformEnum> _$jobResponsePlatformEnumSerializer =
    _$JobResponsePlatformEnumSerializer();

class _$JobResponsePlatformEnumSerializer
    implements PrimitiveSerializer<JobResponsePlatformEnum> {
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
  final Iterable<Type> types = const <Type>[JobResponsePlatformEnum];
  @override
  final String wireName = 'JobResponsePlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    JobResponsePlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  JobResponsePlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => JobResponsePlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$JobResponse extends JobResponse {
  @override
  final String? address;
  @override
  final String? company;
  @override
  final String? companyId;
  @override
  final String? description;
  @override
  final String? education;
  @override
  final String? experience;
  @override
  final DateTime firstSeenAt;
  @override
  final int id;
  @override
  final bool isActive;
  @override
  final String jobId;
  @override
  final DateTime lastUpdatedAt;
  @override
  final String? location;
  @override
  final JobResponsePlatformEnum platform;
  @override
  final String? salary;
  @override
  final int? salaryMax;
  @override
  final int? salaryMin;
  @override
  final int searchConfigId;
  @override
  final String? title;
  @override
  final String? url;
  @override
  final String? applyRecommendation;

  factory _$JobResponse([void Function(JobResponseBuilder)? updates]) =>
      (JobResponseBuilder()..update(updates))._build();

  _$JobResponse._({
    this.address,
    this.company,
    this.companyId,
    this.description,
    this.education,
    this.experience,
    required this.firstSeenAt,
    required this.id,
    required this.isActive,
    required this.jobId,
    required this.lastUpdatedAt,
    this.location,
    required this.platform,
    this.salary,
    this.salaryMax,
    this.salaryMin,
    required this.searchConfigId,
    this.title,
    this.url,
    this.applyRecommendation,
  }) : super._();
  @override
  JobResponse rebuild(void Function(JobResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JobResponseBuilder toBuilder() => JobResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JobResponse &&
        address == other.address &&
        company == other.company &&
        companyId == other.companyId &&
        description == other.description &&
        education == other.education &&
        experience == other.experience &&
        firstSeenAt == other.firstSeenAt &&
        id == other.id &&
        isActive == other.isActive &&
        jobId == other.jobId &&
        lastUpdatedAt == other.lastUpdatedAt &&
        location == other.location &&
        platform == other.platform &&
        salary == other.salary &&
        salaryMax == other.salaryMax &&
        salaryMin == other.salaryMin &&
        searchConfigId == other.searchConfigId &&
        title == other.title &&
        url == other.url &&
        applyRecommendation == other.applyRecommendation;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, company.hashCode);
    _$hash = $jc(_$hash, companyId.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, education.hashCode);
    _$hash = $jc(_$hash, experience.hashCode);
    _$hash = $jc(_$hash, firstSeenAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, jobId.hashCode);
    _$hash = $jc(_$hash, lastUpdatedAt.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, salary.hashCode);
    _$hash = $jc(_$hash, salaryMax.hashCode);
    _$hash = $jc(_$hash, salaryMin.hashCode);
    _$hash = $jc(_$hash, searchConfigId.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jc(_$hash, applyRecommendation.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JobResponse')
          ..add('address', address)
          ..add('company', company)
          ..add('companyId', companyId)
          ..add('description', description)
          ..add('education', education)
          ..add('experience', experience)
          ..add('firstSeenAt', firstSeenAt)
          ..add('id', id)
          ..add('isActive', isActive)
          ..add('jobId', jobId)
          ..add('lastUpdatedAt', lastUpdatedAt)
          ..add('location', location)
          ..add('platform', platform)
          ..add('salary', salary)
          ..add('salaryMax', salaryMax)
          ..add('salaryMin', salaryMin)
          ..add('searchConfigId', searchConfigId)
          ..add('title', title)
          ..add('url', url)
          ..add('applyRecommendation', applyRecommendation))
        .toString();
  }
}

class JobResponseBuilder implements Builder<JobResponse, JobResponseBuilder> {
  _$JobResponse? _$v;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

  String? _company;
  String? get company => _$this._company;
  set company(String? company) => _$this._company = company;

  String? _companyId;
  String? get companyId => _$this._companyId;
  set companyId(String? companyId) => _$this._companyId = companyId;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _education;
  String? get education => _$this._education;
  set education(String? education) => _$this._education = education;

  String? _experience;
  String? get experience => _$this._experience;
  set experience(String? experience) => _$this._experience = experience;

  DateTime? _firstSeenAt;
  DateTime? get firstSeenAt => _$this._firstSeenAt;
  set firstSeenAt(DateTime? firstSeenAt) => _$this._firstSeenAt = firstSeenAt;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  String? _jobId;
  String? get jobId => _$this._jobId;
  set jobId(String? jobId) => _$this._jobId = jobId;

  DateTime? _lastUpdatedAt;
  DateTime? get lastUpdatedAt => _$this._lastUpdatedAt;
  set lastUpdatedAt(DateTime? lastUpdatedAt) =>
      _$this._lastUpdatedAt = lastUpdatedAt;

  String? _location;
  String? get location => _$this._location;
  set location(String? location) => _$this._location = location;

  JobResponsePlatformEnum? _platform;
  JobResponsePlatformEnum? get platform => _$this._platform;
  set platform(JobResponsePlatformEnum? platform) =>
      _$this._platform = platform;

  String? _salary;
  String? get salary => _$this._salary;
  set salary(String? salary) => _$this._salary = salary;

  int? _salaryMax;
  int? get salaryMax => _$this._salaryMax;
  set salaryMax(int? salaryMax) => _$this._salaryMax = salaryMax;

  int? _salaryMin;
  int? get salaryMin => _$this._salaryMin;
  set salaryMin(int? salaryMin) => _$this._salaryMin = salaryMin;

  int? _searchConfigId;
  int? get searchConfigId => _$this._searchConfigId;
  set searchConfigId(int? searchConfigId) =>
      _$this._searchConfigId = searchConfigId;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  String? _applyRecommendation;
  String? get applyRecommendation => _$this._applyRecommendation;
  set applyRecommendation(String? applyRecommendation) =>
      _$this._applyRecommendation = applyRecommendation;

  JobResponseBuilder() {
    JobResponse._defaults(this);
  }

  JobResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _address = $v.address;
      _company = $v.company;
      _companyId = $v.companyId;
      _description = $v.description;
      _education = $v.education;
      _experience = $v.experience;
      _firstSeenAt = $v.firstSeenAt;
      _id = $v.id;
      _isActive = $v.isActive;
      _jobId = $v.jobId;
      _lastUpdatedAt = $v.lastUpdatedAt;
      _location = $v.location;
      _platform = $v.platform;
      _salary = $v.salary;
      _salaryMax = $v.salaryMax;
      _salaryMin = $v.salaryMin;
      _searchConfigId = $v.searchConfigId;
      _title = $v.title;
      _url = $v.url;
      _applyRecommendation = $v.applyRecommendation;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JobResponse other) {
    _$v = other as _$JobResponse;
  }

  @override
  void update(void Function(JobResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JobResponse build() => _build();

  _$JobResponse _build() {
    final _$result =
        _$v ??
        _$JobResponse._(
          address: address,
          company: company,
          companyId: companyId,
          description: description,
          education: education,
          experience: experience,
          firstSeenAt: BuiltValueNullFieldError.checkNotNull(
            firstSeenAt,
            r'JobResponse',
            'firstSeenAt',
          ),
          id: BuiltValueNullFieldError.checkNotNull(id, r'JobResponse', 'id'),
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'JobResponse',
            'isActive',
          ),
          jobId: BuiltValueNullFieldError.checkNotNull(
            jobId,
            r'JobResponse',
            'jobId',
          ),
          lastUpdatedAt: BuiltValueNullFieldError.checkNotNull(
            lastUpdatedAt,
            r'JobResponse',
            'lastUpdatedAt',
          ),
          location: location,
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'JobResponse',
            'platform',
          ),
          salary: salary,
          salaryMax: salaryMax,
          salaryMin: salaryMin,
          searchConfigId: BuiltValueNullFieldError.checkNotNull(
            searchConfigId,
            r'JobResponse',
            'searchConfigId',
          ),
          title: title,
          url: url,
          applyRecommendation: applyRecommendation,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
