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
  });

  final int id;
  final String title;
  final String company;
  final String platform;
  final String location;
  final String status;
}

class JobSearchConfig {
  const JobSearchConfig({
    required this.id,
    required this.name,
    required this.platform,
    required this.keyword,
    required this.location,
    required this.cron,
  });

  final int id;
  final String name;
  final String platform;
  final String keyword;
  final String location;
  final String cron;
}

class ResumeItem {
  const ResumeItem({
    required this.id,
    required this.fileName,
    required this.updatedAt,
  });

  final int id;
  final String fileName;
  final DateTime updatedAt;
}

class JobMatchResult {
  const JobMatchResult({
    required this.jobTitle,
    required this.score,
    required this.reason,
  });

  final String jobTitle;
  final String score;
  final String reason;
}

class CrawlProfileItem {
  const CrawlProfileItem({
    required this.platform,
    required this.profileKey,
    required this.status,
  });

  final String platform;
  final String profileKey;
  final String status;
}

class JobCrawlLog {
  const JobCrawlLog({
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String message;
  final String status;
  final DateTime createdAt;
}

class JobConfigDraft {
  const JobConfigDraft({
    required this.name,
    required this.platform,
    required this.keyword,
    required this.location,
    required this.cron,
  });

  final String name;
  final String platform;
  final String keyword;
  final String location;
  final String cron;
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
  });

  const JobsSnapshot.empty()
    : jobs = const [],
      configs = const [],
      resumes = const [],
      matches = const [],
      profiles = const [],
      crawlLogs = const [];

  final List<JobItem> jobs;
  final List<JobSearchConfig> configs;
  final List<ResumeItem> resumes;
  final List<JobMatchResult> matches;
  final List<CrawlProfileItem> profiles;
  final List<JobCrawlLog> crawlLogs;
}

abstract class JobsRepository {
  Future<JobsSnapshot> loadJobs();

  Future<void> saveConfig(JobConfigDraft draft, {int? configId});

  Future<void> uploadResume(PickedFileReference file);

  Future<void> importProfileBackup(PickedFileReference file);

  Future<ProfileBackupExport> exportProfileBackup(String profileKey);
}
