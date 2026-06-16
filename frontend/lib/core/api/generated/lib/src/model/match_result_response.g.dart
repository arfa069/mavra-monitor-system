// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchResultResponse extends MatchResultResponse {
  @override
  final String? applyRecommendation;
  @override
  final DateTime createdAt;
  @override
  final int id;
  @override
  final int jobId;
  @override
  final String? llmModelUsed;
  @override
  final String? matchReason;
  @override
  final int matchScore;
  @override
  final int resumeId;
  @override
  final DateTime updatedAt;
  @override
  final int userId;
  @override
  final String? jobCompany;
  @override
  final String? jobDescription;
  @override
  final String? jobLocation;
  @override
  final String? jobSalary;
  @override
  final String? jobTitle;
  @override
  final String? jobUrl;

  factory _$MatchResultResponse(
          [void Function(MatchResultResponseBuilder)? updates]) =>
      (MatchResultResponseBuilder()..update(updates))._build();

  _$MatchResultResponse._(
      {this.applyRecommendation,
      required this.createdAt,
      required this.id,
      required this.jobId,
      this.llmModelUsed,
      this.matchReason,
      required this.matchScore,
      required this.resumeId,
      required this.updatedAt,
      required this.userId,
      this.jobCompany,
      this.jobDescription,
      this.jobLocation,
      this.jobSalary,
      this.jobTitle,
      this.jobUrl})
      : super._();
  @override
  MatchResultResponse rebuild(
          void Function(MatchResultResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchResultResponseBuilder toBuilder() =>
      MatchResultResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchResultResponse &&
        applyRecommendation == other.applyRecommendation &&
        createdAt == other.createdAt &&
        id == other.id &&
        jobId == other.jobId &&
        llmModelUsed == other.llmModelUsed &&
        matchReason == other.matchReason &&
        matchScore == other.matchScore &&
        resumeId == other.resumeId &&
        updatedAt == other.updatedAt &&
        userId == other.userId &&
        jobCompany == other.jobCompany &&
        jobDescription == other.jobDescription &&
        jobLocation == other.jobLocation &&
        jobSalary == other.jobSalary &&
        jobTitle == other.jobTitle &&
        jobUrl == other.jobUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, applyRecommendation.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, jobId.hashCode);
    _$hash = $jc(_$hash, llmModelUsed.hashCode);
    _$hash = $jc(_$hash, matchReason.hashCode);
    _$hash = $jc(_$hash, matchScore.hashCode);
    _$hash = $jc(_$hash, resumeId.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, jobCompany.hashCode);
    _$hash = $jc(_$hash, jobDescription.hashCode);
    _$hash = $jc(_$hash, jobLocation.hashCode);
    _$hash = $jc(_$hash, jobSalary.hashCode);
    _$hash = $jc(_$hash, jobTitle.hashCode);
    _$hash = $jc(_$hash, jobUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchResultResponse')
          ..add('applyRecommendation', applyRecommendation)
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('jobId', jobId)
          ..add('llmModelUsed', llmModelUsed)
          ..add('matchReason', matchReason)
          ..add('matchScore', matchScore)
          ..add('resumeId', resumeId)
          ..add('updatedAt', updatedAt)
          ..add('userId', userId)
          ..add('jobCompany', jobCompany)
          ..add('jobDescription', jobDescription)
          ..add('jobLocation', jobLocation)
          ..add('jobSalary', jobSalary)
          ..add('jobTitle', jobTitle)
          ..add('jobUrl', jobUrl))
        .toString();
  }
}

class MatchResultResponseBuilder
    implements Builder<MatchResultResponse, MatchResultResponseBuilder> {
  _$MatchResultResponse? _$v;

  String? _applyRecommendation;
  String? get applyRecommendation => _$this._applyRecommendation;
  set applyRecommendation(String? applyRecommendation) =>
      _$this._applyRecommendation = applyRecommendation;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  int? _jobId;
  int? get jobId => _$this._jobId;
  set jobId(int? jobId) => _$this._jobId = jobId;

  String? _llmModelUsed;
  String? get llmModelUsed => _$this._llmModelUsed;
  set llmModelUsed(String? llmModelUsed) => _$this._llmModelUsed = llmModelUsed;

  String? _matchReason;
  String? get matchReason => _$this._matchReason;
  set matchReason(String? matchReason) => _$this._matchReason = matchReason;

  int? _matchScore;
  int? get matchScore => _$this._matchScore;
  set matchScore(int? matchScore) => _$this._matchScore = matchScore;

  int? _resumeId;
  int? get resumeId => _$this._resumeId;
  set resumeId(int? resumeId) => _$this._resumeId = resumeId;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  String? _jobCompany;
  String? get jobCompany => _$this._jobCompany;
  set jobCompany(String? jobCompany) => _$this._jobCompany = jobCompany;

  String? _jobDescription;
  String? get jobDescription => _$this._jobDescription;
  set jobDescription(String? jobDescription) =>
      _$this._jobDescription = jobDescription;

  String? _jobLocation;
  String? get jobLocation => _$this._jobLocation;
  set jobLocation(String? jobLocation) => _$this._jobLocation = jobLocation;

  String? _jobSalary;
  String? get jobSalary => _$this._jobSalary;
  set jobSalary(String? jobSalary) => _$this._jobSalary = jobSalary;

  String? _jobTitle;
  String? get jobTitle => _$this._jobTitle;
  set jobTitle(String? jobTitle) => _$this._jobTitle = jobTitle;

  String? _jobUrl;
  String? get jobUrl => _$this._jobUrl;
  set jobUrl(String? jobUrl) => _$this._jobUrl = jobUrl;

  MatchResultResponseBuilder() {
    MatchResultResponse._defaults(this);
  }

  MatchResultResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _applyRecommendation = $v.applyRecommendation;
      _createdAt = $v.createdAt;
      _id = $v.id;
      _jobId = $v.jobId;
      _llmModelUsed = $v.llmModelUsed;
      _matchReason = $v.matchReason;
      _matchScore = $v.matchScore;
      _resumeId = $v.resumeId;
      _updatedAt = $v.updatedAt;
      _userId = $v.userId;
      _jobCompany = $v.jobCompany;
      _jobDescription = $v.jobDescription;
      _jobLocation = $v.jobLocation;
      _jobSalary = $v.jobSalary;
      _jobTitle = $v.jobTitle;
      _jobUrl = $v.jobUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchResultResponse other) {
    _$v = other as _$MatchResultResponse;
  }

  @override
  void update(void Function(MatchResultResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchResultResponse build() => _build();

  _$MatchResultResponse _build() {
    final _$result = _$v ??
        _$MatchResultResponse._(
          applyRecommendation: applyRecommendation,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'MatchResultResponse', 'createdAt'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'MatchResultResponse', 'id'),
          jobId: BuiltValueNullFieldError.checkNotNull(
              jobId, r'MatchResultResponse', 'jobId'),
          llmModelUsed: llmModelUsed,
          matchReason: matchReason,
          matchScore: BuiltValueNullFieldError.checkNotNull(
              matchScore, r'MatchResultResponse', 'matchScore'),
          resumeId: BuiltValueNullFieldError.checkNotNull(
              resumeId, r'MatchResultResponse', 'resumeId'),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'MatchResultResponse', 'updatedAt'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'MatchResultResponse', 'userId'),
          jobCompany: jobCompany,
          jobDescription: jobDescription,
          jobLocation: jobLocation,
          jobSalary: jobSalary,
          jobTitle: jobTitle,
          jobUrl: jobUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
