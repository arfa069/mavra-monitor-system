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
    final jobsResponse = await _jobsApi.jobsListJobs(pageSize: 50);
    final configsResponse = await _jobsApi.jobsListConfigs();
    final resumesResponse = await _jobsApi.jobsListResumes();
    final matchesResponse = await _jobsApi.jobsListMatchResults(pageSize: 20);
    final profilesResponse = await _crawlProfilesApi
        .crawlProfilesListProfiles();
    final logsResponse = await _jobsApi.jobsGetJobCrawlLogs(limit: 20);

    final jobs = jobsResponse.data?.items.toList() ?? const [];
    final configs = configsResponse.data?.toList() ?? const [];
    final resumes = resumesResponse.data?.toList() ?? const [];
    final matches = matchesResponse.data?.items.toList() ?? const [];
    final profiles = profilesResponse.data?.toList() ?? const [];
    final logs = logsResponse.data?.toList() ?? const [];

    return JobsSnapshot(
      jobs: [
        for (final job in jobs)
          JobItem(
            id: job.id,
            title: job.title ?? 'Job #${job.id}',
            company: job.company ?? 'Unknown company',
            platform: _platformName(job.platform),
            location: job.location ?? job.address ?? '-',
            status: job.isActive ? 'active' : 'inactive',
          ),
      ],
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
        for (final match in matches)
          JobMatchResult(
            jobTitle: match.jobTitle ?? 'Job #${match.jobId}',
            score: '${match.matchScore}%',
            reason: match.matchReason ?? match.applyRecommendation ?? '-',
          ),
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
    );
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
  Future<void> uploadResume(PickedFileReference file) async {
    final resumeText = await _resumeTextExtractor(file);
    await _jobsApi.jobsCreateResume(
      userResumeCreate: generated.UserResumeCreate(
        (builder) => builder
          ..name = file.name
          ..resumeText = resumeText,
      ),
    );
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

  static String _platformName(Object? value) {
    final raw = value?.toString().split('.').last ?? '-';
    return raw == 'n51job' ? '51job' : raw;
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
