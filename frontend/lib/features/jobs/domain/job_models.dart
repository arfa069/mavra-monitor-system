import '../../../core/files/file_service.dart';

typedef ResumeTextExtractor = Future<String> Function(PickedFileReference file);

class JobItem {
  const JobItem({
    required this.id,
    required this.title,
    required this.company,
    required this.platform,
    required this.location,
    required this.status,
    this.jobId,
    this.salary,
    this.updatedAt,
    this.url,
    this.matchRecommendation,
  });

  final int id;
  final String title;
  final String company;
  final String platform;
  final String location;
  final String status;
  final String? jobId;
  final String? salary;
  final String? updatedAt;
  final String? url;
  final String? matchRecommendation;
}

class JobListQuery {
  const JobListQuery({
    this.searchConfigId,
    this.keyword,
    this.status,
    this.page = 1,
    this.pageSize = 20,
  });

  final int? searchConfigId;
  final String? keyword;
  final String? status;
  final int page;
  final int pageSize;
}

class JobPageState {
  const JobPageState({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<JobItem> items;
  final int page;
  final int pageSize;
  final int total;
}

class JobDetail {
  const JobDetail({
    required this.id,
    required this.title,
    required this.company,
    this.description,
    this.url,
    this.salary,
    this.location,
    this.experience,
    this.education,
    this.status,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String company;
  final String? description;
  final String? url;
  final String? salary;
  final String? location;
  final String? experience;
  final String? education;
  final String? status;
  final String? updatedAt;
}

class JobSearchConfig {
  const JobSearchConfig({
    required this.id,
    required this.name,
    required this.platform,
    required this.keyword,
    required this.location,
    required this.cron,
    this.url,
    this.profileKey,
    this.cityCode,
    this.salaryMin,
    this.salaryMax,
    this.experience,
    this.education,
    this.active = true,
    this.notifyOnNew = true,
    this.enableMatchAnalysis = false,
    this.deactivationThreshold = 3,
  });

  final int id;
  final String name;
  final String platform;
  final String keyword;
  final String location;
  final String cron;
  final String? url;
  final String? profileKey;
  final String? cityCode;
  final int? salaryMin;
  final int? salaryMax;
  final String? experience;
  final String? education;
  final bool active;
  final bool notifyOnNew;
  final bool enableMatchAnalysis;
  final int deactivationThreshold;
}

class ResumeItem {
  const ResumeItem({
    required this.id,
    required this.fileName,
    required this.updatedAt,
    this.resumeText = '',
  });

  final int id;
  final String fileName;
  final DateTime updatedAt;
  final String resumeText;
}

class ResumeDraft {
  const ResumeDraft({required this.name, required this.resumeText});

  final String name;
  final String resumeText;
}

class JobMatchResult {
  const JobMatchResult({
    required this.jobTitle,
    required this.score,
    required this.reason,
    this.company,
    this.salary,
    this.recommendation,
    this.updatedAt,
    this.url,
  });

  final String jobTitle;
  final String score;
  final String reason;
  final String? company;
  final String? salary;
  final String? recommendation;
  final String? updatedAt;
  final String? url;
}

class CrawlProfileItem {
  const CrawlProfileItem({
    required this.platform,
    required this.profileKey,
    required this.status,
    this.taskId,
    this.leaseUntil,
    this.lastError,
  });

  final String platform;
  final String profileKey;
  final String status;
  final String? taskId;
  final String? leaseUntil;
  final String? lastError;
}

class JobCrawlLog {
  const JobCrawlLog({
    required this.message,
    required this.status,
    required this.createdAt,
    this.configId,
    this.newJobs,
    this.totalJobs,
    this.error,
  });

  final String message;
  final String status;
  final DateTime createdAt;
  final int? configId;
  final int? newJobs;
  final int? totalJobs;
  final String? error;
}

class JobConfigDraft {
  const JobConfigDraft({
    required this.name,
    required this.platform,
    required this.keyword,
    required this.location,
    required this.cron,
    this.url,
    this.profileKey,
    this.cityCode,
    this.salaryMin,
    this.salaryMax,
    this.experience,
    this.education,
    this.active = true,
    this.notifyOnNew = true,
    this.enableMatchAnalysis = false,
    this.deactivationThreshold = 3,
  });

  final String name;
  final String platform;
  final String keyword;
  final String location;
  final String cron;
  final String? url;
  final String? profileKey;
  final String? cityCode;
  final int? salaryMin;
  final int? salaryMax;
  final String? experience;
  final String? education;
  final bool active;
  final bool notifyOnNew;
  final bool enableMatchAnalysis;
  final int deactivationThreshold;
}

class ProfileBackupExport {
  const ProfileBackupExport({required this.fileName, required this.bytes});

  final String fileName;
  final List<int> bytes;
}

class JobsSnapshot {
  const JobsSnapshot({
    required this.jobs,
    required this.configs,
    required this.resumes,
    required this.matches,
    required this.profiles,
    required this.crawlLogs,
    JobPageState? page,
  }) : page =
           page ??
           const JobPageState(items: [], page: 1, pageSize: 20, total: 0);

  const JobsSnapshot.empty()
    : jobs = const [],
      configs = const [],
      resumes = const [],
      matches = const [],
      profiles = const [],
      crawlLogs = const [],
      page = const JobPageState(items: [], page: 1, pageSize: 20, total: 0);

  final List<JobItem> jobs;
  final List<JobSearchConfig> configs;
  final List<ResumeItem> resumes;
  final List<JobMatchResult> matches;
  final List<CrawlProfileItem> profiles;
  final List<JobCrawlLog> crawlLogs;
  final JobPageState page;
}

abstract class JobsRepository {
  Future<JobsSnapshot> loadJobs();

  Future<JobPageState> listJobs(JobListQuery query);

  Future<JobDetail> loadJobDetail(int jobId);

  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  });

  Future<void> saveConfig(JobConfigDraft draft, {int? configId});

  Future<void> deleteConfig(int configId);

  Future<void> requestCrawlAll();

  Future<void> requestCrawlConfig(int configId);

  Future<void> requestMatchAnalysis(int jobId, {required int resumeId});

  Future<void> uploadResume(PickedFileReference file);

  Future<void> createResume(ResumeDraft draft);

  Future<void> updateResume(int resumeId, ResumeDraft draft);

  Future<void> deleteResume(int resumeId);

  Future<void> selectResumeForMatch(int resumeId);

  Future<void> importProfileBackup(PickedFileReference file);

  Future<ProfileBackupExport> exportProfileBackup(String profileKey);

  Future<void> createProfile({
    required String profileKey,
    required String platform,
  });

  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  });

  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  });

  Future<void> copyProfile(String profileKey);

  Future<void> deleteProfile(String profileKey);

  Future<void> releaseStaleProfile(String profileKey);

  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  });

  Future<void> closeProfileLoginSession(String profileKey);

  Future<void> testProfile({
    required String profileKey,
    required String platform,
  });
}
