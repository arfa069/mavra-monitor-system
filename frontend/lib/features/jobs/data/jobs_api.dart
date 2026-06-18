import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../../../core/files/file_service.dart';
import '../domain/job_models.dart';

class GeneratedJobsRepository implements JobsRepository {
  GeneratedJobsRepository({
    required AppConfig config,
    generated.MavraApi? client,
    this.backupPassword,
    ResumeTextExtractor? resumeTextExtractor,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           ),
       _resumeTextExtractor =
           resumeTextExtractor ?? _defaultResumeTextExtractor;

  final generated.MavraApi _client;
  final String? backupPassword;
  final ResumeTextExtractor _resumeTextExtractor;

  generated.JobsApi get _jobsApi => _client.getJobsApi();

  generated.CrawlProfilesApi get _crawlProfilesApi =>
      _client.getCrawlProfilesApi();

  @override
  Future<JobsSnapshot> loadJobs() async {
    final jobPage = await listJobs(const JobListQuery(page: 1, pageSize: 50));
    final configsResponse = await _jobsApi.jobsListConfigs();
    final resumesResponse = await _jobsApi.jobsListResumes();
    final matchesResponse = await _jobsApi.jobsListMatchResults(pageSize: 20);
    final profilesResponse = await _crawlProfilesApi
        .crawlProfilesListProfiles();
    final logsResponse = await _jobsApi.jobsGetJobCrawlLogs(limit: 20);

    final configs = configsResponse.data?.toList() ?? const [];
    final resumes = resumesResponse.data?.toList() ?? const [];
    final matches = matchesResponse.data?.items.toList() ?? const [];
    final profiles = profilesResponse.data?.toList() ?? const [];
    final logs = logsResponse.data?.toList() ?? const [];

    return JobsSnapshot(
      jobs: jobPage.items,
      configs: [
        for (final config in configs)
          JobSearchConfig(
            id: config.id,
            name: config.name,
            platform: _platformName(config.platform),
            keyword: config.keyword ?? '-',
            location: config.cityCode ?? '-',
            cron: config.cronExpression ?? 'Disabled',
          ),
      ],
      resumes: [
        for (final resume in resumes)
          ResumeItem(
            id: resume.id,
            fileName: resume.name,
            updatedAt: resume.updatedAt,
          ),
      ],
      matches: [
        for (final match in matches) _mapMatch(match),
      ],
      profiles: [
        for (final profile in profiles)
          CrawlProfileItem(
            platform: profile.platformHint ?? 'jobs',
            profileKey: profile.profileKey,
            status: _platformName(profile.status),
          ),
      ],
      crawlLogs: [
        for (final log in logs)
          JobCrawlLog(
            message: log.errorMessage ?? _jobLogMessage(log),
            status: log.status,
            createdAt: log.scrapedAt,
          ),
      ],
      page: jobPage,
    );
  }

  @override
  Future<JobPageState> listJobs(JobListQuery query) async {
    final response = await _jobsApi.jobsListJobs(
      searchConfigId: query.searchConfigId,
      keyword: query.keyword,
      isActive: _statusToActive(query.status),
      page: query.page,
      pageSize: query.pageSize,
    );
    final data = response.data;
    return JobPageState(
      items: [
        for (final job in data?.items.toList() ?? const []) _mapJob(job),
      ],
      page: data?.page ?? query.page,
      pageSize: data?.pageSize ?? query.pageSize,
      total: data?.total ?? 0,
    );
  }

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    final response = await _jobsApi.jobsGetJob(jobIdStr: '$jobId');
    final job = response.data;
    if (job == null) {
      throw StateError('Job #$jobId was not returned by the API.');
    }
    return JobDetail(
      id: job.id,
      title: job.title ?? 'Job #${job.id}',
      company: job.company ?? 'Unknown company',
      description: job.description,
      url: job.url,
    );
  }

  @override
  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _jobsApi.jobsListMatchResults(
      resumeId: resumeId,
      jobId: jobId,
      page: page,
      pageSize: pageSize,
    );
    return [
      for (final match in response.data?.items.toList() ?? const [])
        _mapMatch(match),
    ];
  }

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {
    if (configId == null) {
      await _jobsApi.jobsCreateConfig(
        jobSearchConfigCreate: generated.JobSearchConfigCreate(
          (builder) => builder
            ..name = draft.name
            ..keyword = draft.keyword
            ..cityCode = draft.location
            ..cronExpression = draft.cron
            ..cronTimezone = 'Asia/Shanghai'
            ..platform = _createPlatform(draft.platform)
            ..profileKey = 'default'
            ..url = _searchUrl(draft),
        ),
      );
      return;
    }

    await _jobsApi.jobsUpdateConfig(
      configId: configId,
      jobSearchConfigUpdate: generated.JobSearchConfigUpdate(
        (builder) => builder
          ..name = draft.name
          ..keyword = draft.keyword
          ..cityCode = draft.location
          ..cronExpression = draft.cron
          ..cronTimezone = 'Asia/Shanghai'
          ..platform = _updatePlatform(draft.platform)
          ..profileKey = 'default'
          ..url = _searchUrl(draft),
      ),
    );
  }

  @override
  Future<void> deleteConfig(int configId) async {
    await _jobsApi.jobsDeleteConfig(configId: configId);
  }

  @override
  Future<void> requestCrawlAll() async {
    await _jobsApi.jobsCrawlNow();
  }

  @override
  Future<void> requestCrawlConfig(int configId) async {
    await _jobsApi.jobsCrawlSingle(configId: configId);
  }

  @override
  Future<void> requestMatchAnalysis(int jobId, {required int resumeId}) async {
    await _jobsApi.jobsTriggerMatchAnalysis(
      matchAnalyzeRequest: generated.MatchAnalyzeRequest(
        (builder) => builder
          ..resumeId = resumeId
          ..jobIds.replace([jobId]),
      ),
    );
  }

  @override
  Future<void> uploadResume(PickedFileReference file) async {
    final resumeText = await _resumeTextExtractor(file);
    await createResume(ResumeDraft(name: file.name, resumeText: resumeText));
  }

  @override
  Future<void> createResume(ResumeDraft draft) async {
    await _jobsApi.jobsCreateResume(
      userResumeCreate: generated.UserResumeCreate(
        (builder) => builder
          ..name = draft.name
          ..resumeText = draft.resumeText,
      ),
    );
  }

  @override
  Future<void> updateResume(int resumeId, ResumeDraft draft) async {
    await _jobsApi.jobsUpdateResume(
      resumeId: resumeId,
      userResumeUpdate: generated.UserResumeUpdate(
        (builder) => builder
          ..name = draft.name
          ..resumeText = draft.resumeText,
      ),
    );
  }

  @override
  Future<void> deleteResume(int resumeId) async {
    await _jobsApi.jobsDeleteResume(resumeId: resumeId);
  }

  @override
  Future<void> selectResumeForMatch(int resumeId) async {
    // Selection is UI state; the API receives the resume id when match starts.
  }

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {
    final password = _requireBackupPassword();
    final bytes = file.bytes;
    if (bytes == null) {
      throw UnsupportedError('Profile backup imports require readable bytes.');
    }
    await _crawlProfilesApi.crawlProfilesImportProfileBackup(
      profileKey: 'default',
      password: password,
      force: true,
      file: MultipartFile.fromBytes(bytes, filename: file.name),
    );
  }

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    final password = _requireBackupPassword();
    final response = await _crawlProfilesApi.crawlProfilesExportProfileBackup(
      profileKey: profileKey,
      crawlProfileBackupExportRequest:
          generated.CrawlProfileBackupExportRequest(
            (builder) => builder.password = password,
          ),
    );
    return ProfileBackupExport(
      fileName: '$profileKey.zip',
      bytes: response.data?.toList() ?? const [],
    );
  }

  @override
  Future<void> createProfile({
    required String profileKey,
    required String platform,
  }) async {
    await _crawlProfilesApi.crawlProfilesCreateProfile(
      crawlProfileCreate: generated.CrawlProfileCreate(
        (builder) => builder
          ..profileKey = profileKey
          ..platformHint = platform,
      ),
    );
  }

  @override
  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  }) async {
    await _crawlProfilesApi.crawlProfilesUpdateProfile(
      profileKey: profileKey,
      crawlProfileUpdate: generated.CrawlProfileUpdate(
        (builder) => builder.status = _profileStatus(status),
      ),
    );
  }

  @override
  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  }) async {
    await _crawlProfilesApi.crawlProfilesRenameProfile(
      profileKey: profileKey,
      crawlProfileRenameRequest: generated.CrawlProfileRenameRequest(
        (builder) => builder.profileKey = newProfileKey,
      ),
    );
  }

  @override
  Future<void> copyProfile(String profileKey) async {
    await _crawlProfilesApi.crawlProfilesCopyProfile(profileKey: profileKey);
  }

  @override
  Future<void> deleteProfile(String profileKey) async {
    await _crawlProfilesApi.crawlProfilesDeleteProfile(profileKey: profileKey);
  }

  @override
  Future<void> releaseStaleProfile(String profileKey) async {
    await _crawlProfilesApi.crawlProfilesReleaseStaleProfile(
      profileKey: profileKey,
    );
  }

  @override
  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  }) async {
    await _crawlProfilesApi.crawlProfilesOpenLoginSession(
      profileKey: profileKey,
      crawlProfileLoginSessionRequest:
          generated.CrawlProfileLoginSessionRequest(
            (builder) => builder.platform = platform,
          ),
    );
  }

  @override
  Future<void> closeProfileLoginSession(String profileKey) async {
    await _crawlProfilesApi.crawlProfilesCloseLoginSession(
      profileKey: profileKey,
    );
  }

  @override
  Future<void> testProfile({
    required String profileKey,
    required String platform,
  }) async {
    await _crawlProfilesApi.crawlProfilesTestProfile(
      profileKey: profileKey,
      crawlProfileTestRequest: generated.CrawlProfileTestRequest(
        (builder) => builder.platform = platform,
      ),
    );
  }

  String _requireBackupPassword() {
    final password = backupPassword;
    if (password == null || password.isEmpty) {
      throw UnsupportedError('Profile backup password is not configured.');
    }
    return password;
  }

  static generated.JobSearchConfigCreatePlatformEnum _createPlatform(
    String value,
  ) {
    switch (value.toLowerCase()) {
      case '51job':
        return generated.JobSearchConfigCreatePlatformEnum.n51job;
      case 'liepin':
        return generated.JobSearchConfigCreatePlatformEnum.liepin;
      default:
        return generated.JobSearchConfigCreatePlatformEnum.boss;
    }
  }

  static generated.JobSearchConfigUpdatePlatformEnum _updatePlatform(
    String value,
  ) {
    switch (value.toLowerCase()) {
      case '51job':
        return generated.JobSearchConfigUpdatePlatformEnum.n51job;
      case 'liepin':
        return generated.JobSearchConfigUpdatePlatformEnum.liepin;
      default:
        return generated.JobSearchConfigUpdatePlatformEnum.boss;
    }
  }

  static generated.CrawlProfileUpdateStatusEnum _profileStatus(String value) {
    switch (value.toLowerCase()) {
      case 'disabled':
        return generated.CrawlProfileUpdateStatusEnum.disabled;
      case 'login_required':
      case 'login required':
        return generated.CrawlProfileUpdateStatusEnum.loginRequired;
      default:
        return generated.CrawlProfileUpdateStatusEnum.available;
    }
  }

  static String _platformName(Object? value) {
    final raw = value?.toString().split('.').last ?? '-';
    return raw == 'n51job' ? '51job' : raw;
  }

  static bool? _statusToActive(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return true;
      case 'inactive':
        return false;
      default:
        return null;
    }
  }

  static JobItem _mapJob(generated.JobResponse job) {
    return JobItem(
      id: job.id,
      title: job.title ?? 'Job #${job.id}',
      company: job.company ?? 'Unknown company',
      platform: _platformName(job.platform),
      location: job.location ?? job.address ?? '-',
      status: job.isActive ? 'active' : 'inactive',
    );
  }

  static JobMatchResult _mapMatch(generated.MatchResultResponse match) {
    return JobMatchResult(
      jobTitle: match.jobTitle ?? 'Job #${match.jobId}',
      score: '${match.matchScore}%',
      reason: match.matchReason ?? match.applyRecommendation ?? '-',
    );
  }

  static String _searchUrl(JobConfigDraft draft) {
    final keyword = Uri.encodeQueryComponent(draft.keyword);
    final city = Uri.encodeQueryComponent(draft.location);
    return 'https://jobs.example/${draft.platform}?q=$keyword&city=$city';
  }

  static String _jobLogMessage(generated.JobCrawlLogResponse log) {
    final newJobs = log.newJobsCount ?? 0;
    final totalJobs = log.totalJobsCount ?? 0;
    return 'Crawled $totalJobs jobs, $newJobs new';
  }

  static Future<String> _defaultResumeTextExtractor(
    PickedFileReference file,
  ) async {
    if (file.name.toLowerCase().endsWith('.pdf')) {
      throw UnsupportedError(
        'PDF resume parsing requires a platform text extractor.',
      );
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw UnsupportedError('Resume upload requires readable file bytes.');
    }
    return utf8.decode(bytes);
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
