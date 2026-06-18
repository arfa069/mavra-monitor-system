import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/files/file_service.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';
import 'package:mavra_frontend/features/jobs/domain/job_models.dart';
import 'package:mavra_frontend/features/jobs/presentation/jobs_page.dart';

void main() {
  testWidgets(
    'renders jobs, configs, schedules, resumes, matches, profiles, and logs',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: JobsPage(repository: _FakeJobsRepository.full())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Senior Flutter Engineer'), findsOneWidget);
      expect(find.text('Mavra Labs'), findsOneWidget);
      expect(find.text('Boss Zhipin'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('0 8 * * *'), findsOneWidget);
      expect(find.text('Resume manager'), findsOneWidget);
      expect(find.text('resume.pdf'), findsOneWidget);
      expect(find.text('Match results'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('Profile management'), findsOneWidget);
      expect(find.text('boss-main'), findsOneWidget);
      expect(find.text('Crawl logs'), findsOneWidget);
      expect(find.text('Job crawl completed'), findsOneWidget);
      expect(find.byKey(const Key('job-tab-configs')), findsOneWidget);
      expect(find.byKey(const Key('job-tab-jobs')), findsOneWidget);
      expect(find.byKey(const Key('job-tab-matches')), findsOneWidget);
      expect(find.byKey(const Key('job-tab-resumes')), findsOneWidget);
      expect(find.byKey(const Key('job-tab-profiles')), findsOneWidget);
      expect(find.byKey(const Key('job-tab-logs')), findsOneWidget);
    },
  );

  testWidgets(
    'exposes safe crawl, match, resume, and profile management intents',
    (tester) async {
      final repository = _FakeJobsRepository.full();

      await tester.pumpWidget(
        MaterialApp(home: JobsPage(repository: repository)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job-crawl-all-button')));
      await tester.pumpAndSettle();
      expect(repository.crawlAllRequested, isTrue);
      expect(find.text('Job crawl requested'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('job-crawl-config-7-button')),
      );
      await tester.tap(find.byKey(const Key('job-crawl-config-7-button')));
      await tester.pumpAndSettle();
      expect(repository.crawledConfigId, 7);

      await tester.ensureVisible(find.byKey(const Key('job-detail-1-button')));
      await tester.tap(find.byKey(const Key('job-detail-1-button')));
      await tester.pumpAndSettle();
      expect(find.text('Job details: Senior Flutter Engineer'), findsOneWidget);
      await tester.tap(find.byKey(const Key('job-match-1-button')));
      await tester.pumpAndSettle();
      expect(repository.matchedJobId, 1);
      expect(repository.matchedResumeId, 3);

      await tester.ensureVisible(
        find.byKey(const Key('job-resume-delete-3-button')),
      );
      await tester.tap(find.byKey(const Key('job-resume-delete-3-button')));
      await tester.pumpAndSettle();
      expect(repository.deletedResumeId, 3);

      await tester.ensureVisible(
        find.byKey(const Key('job-profile-copy-boss-main-button')),
      );
      await tester.tap(
        find.byKey(const Key('job-profile-copy-boss-main-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.copiedProfileKey, 'boss-main');

      await tester.tap(
        find.byKey(const Key('job-profile-release-boss-main-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.releasedProfileKey, 'boss-main');

      await tester.tap(
        find.byKey(const Key('job-profile-login-boss-main-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.openedLoginProfileKey, 'boss-main');

      await tester.tap(
        find.byKey(const Key('job-profile-test-boss-main-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.testedProfileKey, 'boss-main');
    },
  );

  testWidgets('matches React jobs workbench parity interactions', (
    tester,
  ) async {
    final repository = _FakeJobsRepository.full();
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('job-keyword-filter')), findsOneWidget);
    expect(find.byKey(const Key('job-status-filter')), findsOneWidget);
    expect(find.byKey(const Key('job-page-size-field')), findsOneWidget);
    expect(find.byType(MavraResponsiveDataView<JobItem>), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);

    await tester.enterText(find.byKey(const Key('job-keyword-filter')), 'ai');
    await tester.enterText(find.byKey(const Key('job-page-size-field')), '10');
    await tester.tap(find.text('Inactive'));
    await tester.tap(find.byKey(const Key('job-apply-filters-button')));
    await tester.pumpAndSettle();

    expect(repository.lastListQuery.keyword, 'ai');
    expect(repository.lastListQuery.status, 'inactive');
    expect(repository.lastListQuery.pageSize, 10);

    await tester.tap(find.byKey(const Key('job-detail-1-button')));
    await tester.pumpAndSettle();

    expect(repository.loadedJobDetailId, 1);
    expect(find.byKey(const Key('mavra-side-sheet-panel')), findsOneWidget);
    expect(find.text('Fake job detail'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('job-tab-resumes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('job-resume-create-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('job-resume-name-field')),
      'frontend resume',
    );
    await tester.enterText(
      find.byKey(const Key('job-resume-text-field')),
      'Flutter, Windows, API integration',
    );
    await tester.tap(find.byKey(const Key('job-resume-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdResumeDraft?.name, 'frontend resume');

    await tester.tap(find.byKey(const Key('job-resume-edit-3-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('job-resume-name-field')),
      'resume revised',
    );
    await tester.tap(find.byKey(const Key('job-resume-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedResumeId, 3);
    expect(repository.updatedResumeDraft?.name, 'resume revised');

    await tester.tap(find.byKey(const Key('job-resume-select-3-button')));
    await tester.pumpAndSettle();

    expect(repository.selectedResumeId, 3);
  });

  testWidgets('creates and edits a job search config from the form', (
    tester,
  ) async {
    final repository = _FakeJobsRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New config'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('job-config-name-field')),
      'Liepin data',
    );
    await tester.enterText(
      find.byKey(const Key('job-keyword-field')),
      'data engineer',
    );
    await tester.enterText(
      find.byKey(const Key('job-location-field')),
      'Shenzhen',
    );
    await tester.enterText(
      find.byKey(const Key('job-platform-field')),
      'liepin',
    );
    await tester.enterText(
      find.byKey(const Key('job-cron-field')),
      '0 10 * * *',
    );
    await tester.ensureVisible(find.text('Save config'));
    await tester.tap(find.text('Save config'));
    await tester.pumpAndSettle();

    expect(repository.savedDrafts.last.keyword, 'data engineer');
    expect(repository.savedDrafts.last.platform, 'liepin');

    await tester.ensureVisible(find.text('Edit Boss Zhipin'));
    await tester.tap(find.text('Edit Boss Zhipin'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('job-keyword-field')));
    await tester.enterText(
      find.byKey(const Key('job-keyword-field')),
      'flutter lead',
    );
    await tester.ensureVisible(find.text('Save config'));
    await tester.tap(find.text('Save config'));
    await tester.pumpAndSettle();

    expect(repository.updatedConfigId, 7);
    expect(repository.savedDrafts.last.keyword, 'flutter lead');
  });

  testWidgets('uploads resumes and imports/exports profile backups', (
    tester,
  ) async {
    final repository = _FakeJobsRepository.full();
    final fileService = _FakeFileService();

    await tester.pumpWidget(
      MaterialApp(
        home: JobsPage(repository: repository, fileService: fileService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upload resume'));
    await tester.pumpAndSettle();
    expect(repository.uploadedResumeName, 'resume-new.pdf');
    expect(find.text('Uploaded resume-new.pdf'), findsOneWidget);

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    expect(repository.importedBackupName, 'profiles.zip');
    expect(find.text('Imported profiles.zip'), findsOneWidget);

    await tester.ensureVisible(find.text('Export backup boss-main'));
    await tester.tap(find.text('Export backup boss-main'));
    await tester.pumpAndSettle();
    expect(repository.exportedProfileKey, 'boss-main');
    expect(fileService.savedName, 'boss-main.zip');
  });

  testWidgets('renders loading, empty, and error states', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: _SlowJobsRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: _FakeJobsRepository.empty())),
    );
    await tester.pumpAndSettle();
    expect(find.text('No jobs yet'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: _FailingJobsRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jobs unavailable'), findsOneWidget);
  });

  testWidgets('disables dangerous crawl and profile actions without permission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JobsPage(
          repository: _FakeJobsRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final crawlAll = tester.widget<TextButton>(
      find.byKey(const Key('job-crawl-all-button')),
    );
    expect(crawlAll.onPressed, isNull);

    final profileLogin = tester.widget<IconButton>(
      find.byKey(const Key('job-profile-login-boss-main-button')),
    );
    expect(profileLogin.onPressed, isNull);

    await tester.tap(find.byKey(const Key('job-detail-1-button')));
    await tester.pumpAndSettle();

    final match = tester.widget<FilledButton>(
      find.byKey(const Key('job-match-1-button')),
    );
    expect(match.onPressed, isNull);
  });
}

class _FakeJobsRepository implements JobsRepository {
  _FakeJobsRepository(this.snapshot);

  factory _FakeJobsRepository.full() => _FakeJobsRepository(
    JobsSnapshot(
      jobs: const [
        JobItem(
          id: 1,
          title: 'Senior Flutter Engineer',
          company: 'Mavra Labs',
          platform: 'boss',
          location: 'Shanghai',
          status: 'new',
        ),
      ],
      configs: const [
        JobSearchConfig(
          id: 7,
          name: 'Boss Zhipin',
          platform: 'boss',
          keyword: 'flutter',
          location: 'Shanghai',
          cron: '0 8 * * *',
        ),
      ],
      resumes: [
        ResumeItem(
          id: 3,
          fileName: 'resume.pdf',
          updatedAt: DateTime.utc(2026, 6, 16, 9),
        ),
      ],
      matches: const [
        JobMatchResult(
          jobTitle: 'Senior Flutter Engineer',
          score: '92%',
          reason: 'Strong Flutter and Windows desktop fit',
        ),
      ],
      profiles: const [
        CrawlProfileItem(
          platform: 'boss',
          profileKey: 'boss-main',
          status: 'ready',
        ),
      ],
      crawlLogs: [
        JobCrawlLog(
          message: 'Job crawl completed',
          status: 'success',
          createdAt: DateTime.utc(2026, 6, 16, 8),
        ),
      ],
    ),
  );

  factory _FakeJobsRepository.empty() => _FakeJobsRepository(
    const JobsSnapshot(
      jobs: [],
      configs: [],
      resumes: [],
      matches: [],
      profiles: [],
      crawlLogs: [],
    ),
  );

  final JobsSnapshot snapshot;
  final savedDrafts = <JobConfigDraft>[];
  int? updatedConfigId;
  String? uploadedResumeName;
  String? importedBackupName;
  String? exportedProfileKey;
  bool crawlAllRequested = false;
  int? crawledConfigId;
  int? deletedConfigId;
  int? loadedJobDetailId;
  int? matchedJobId;
  int? matchedResumeId;
  int? deletedResumeId;
  String? createdProfileKey;
  String? updatedProfileKey;
  String? renamedProfileKey;
  String? copiedProfileKey;
  String? deletedProfileKey;
  String? releasedProfileKey;
  String? openedLoginProfileKey;
  String? closedLoginProfileKey;
  String? testedProfileKey;
  JobListQuery lastListQuery = const JobListQuery();
  ResumeDraft? createdResumeDraft;
  int? updatedResumeId;
  ResumeDraft? updatedResumeDraft;
  int? selectedResumeId;

  @override
  Future<JobsSnapshot> loadJobs() async => snapshot;

  @override
  Future<JobPageState> listJobs(JobListQuery query) async {
    lastListQuery = query;
    return JobPageState(
      items: snapshot.jobs,
      page: query.page,
      pageSize: query.pageSize,
      total: snapshot.jobs.length,
    );
  }

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    loadedJobDetailId = jobId;
    final job = snapshot.jobs.firstWhere((item) => item.id == jobId);
    return JobDetail(
      id: job.id,
      title: job.title,
      company: job.company,
      description: 'Fake job detail',
      url: 'https://jobs.example/$jobId',
    );
  }

  @override
  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return snapshot.matches;
  }

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {
    savedDrafts.add(draft);
    updatedConfigId = configId;
  }

  @override
  Future<void> uploadResume(PickedFileReference file) async {
    uploadedResumeName = file.name;
  }

  @override
  Future<void> createResume(ResumeDraft draft) async {
    createdResumeDraft = draft;
  }

  @override
  Future<void> updateResume(int resumeId, ResumeDraft draft) async {
    updatedResumeId = resumeId;
    updatedResumeDraft = draft;
  }

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {
    importedBackupName = file.name;
  }

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    exportedProfileKey = profileKey;
    return ProfileBackupExport(fileName: '$profileKey.zip', bytes: const [9]);
  }

  @override
  Future<void> deleteConfig(int configId) async {
    deletedConfigId = configId;
  }

  @override
  Future<void> requestCrawlAll() async {
    crawlAllRequested = true;
  }

  @override
  Future<void> requestCrawlConfig(int configId) async {
    crawledConfigId = configId;
  }

  @override
  Future<void> requestMatchAnalysis(int jobId, {required int resumeId}) async {
    matchedJobId = jobId;
    matchedResumeId = resumeId;
  }

  @override
  Future<void> deleteResume(int resumeId) async {
    deletedResumeId = resumeId;
  }

  @override
  Future<void> selectResumeForMatch(int resumeId) async {
    selectedResumeId = resumeId;
  }

  @override
  Future<void> createProfile({
    required String profileKey,
    required String platform,
  }) async {
    createdProfileKey = profileKey;
  }

  @override
  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  }) async {
    updatedProfileKey = profileKey;
  }

  @override
  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  }) async {
    renamedProfileKey = newProfileKey;
  }

  @override
  Future<void> copyProfile(String profileKey) async {
    copiedProfileKey = profileKey;
  }

  @override
  Future<void> deleteProfile(String profileKey) async {
    deletedProfileKey = profileKey;
  }

  @override
  Future<void> releaseStaleProfile(String profileKey) async {
    releasedProfileKey = profileKey;
  }

  @override
  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  }) async {
    openedLoginProfileKey = profileKey;
  }

  @override
  Future<void> closeProfileLoginSession(String profileKey) async {
    closedLoginProfileKey = profileKey;
  }

  @override
  Future<void> testProfile({
    required String profileKey,
    required String platform,
  }) async {
    testedProfileKey = profileKey;
  }
}

class _SlowJobsRepository implements JobsRepository {
  final _completer = Completer<JobsSnapshot>();

  @override
  Future<JobsSnapshot> loadJobs() => _completer.future;

  @override
  Future<JobPageState> listJobs(JobListQuery query) async {
    return JobPageState(
      items: const [],
      page: query.page,
      pageSize: query.pageSize,
      total: 0,
    );
  }

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {}

  @override
  Future<void> uploadResume(PickedFileReference file) async {}

  @override
  Future<void> createResume(ResumeDraft draft) async {}

  @override
  Future<void> updateResume(int resumeId, ResumeDraft draft) async {}

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {}

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    return const ProfileBackupExport(fileName: 'backup.zip', bytes: []);
  }

  @override
  Future<void> deleteConfig(int configId) async {}

  @override
  Future<void> requestCrawlAll() async {}

  @override
  Future<void> requestCrawlConfig(int configId) async {}

  @override
  Future<void> requestMatchAnalysis(int jobId, {required int resumeId}) async {}

  @override
  Future<void> deleteResume(int resumeId) async {}

  @override
  Future<void> selectResumeForMatch(int resumeId) async {}

  @override
  Future<void> createProfile({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  }) async {}

  @override
  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  }) async {}

  @override
  Future<void> copyProfile(String profileKey) async {}

  @override
  Future<void> deleteProfile(String profileKey) async {}

  @override
  Future<void> releaseStaleProfile(String profileKey) async {}

  @override
  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> closeProfileLoginSession(String profileKey) async {}

  @override
  Future<void> testProfile({
    required String profileKey,
    required String platform,
  }) async {}
}

class _FailingJobsRepository implements JobsRepository {
  @override
  Future<JobsSnapshot> loadJobs() {
    throw StateError('jobs down');
  }

  @override
  Future<JobPageState> listJobs(JobListQuery query) async {
    throw StateError('jobs down');
  }

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    throw StateError('jobs down');
  }

  @override
  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {}

  @override
  Future<void> uploadResume(PickedFileReference file) async {}

  @override
  Future<void> createResume(ResumeDraft draft) async {}

  @override
  Future<void> updateResume(int resumeId, ResumeDraft draft) async {}

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {}

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    return const ProfileBackupExport(fileName: 'backup.zip', bytes: []);
  }

  @override
  Future<void> deleteConfig(int configId) async {}

  @override
  Future<void> requestCrawlAll() async {}

  @override
  Future<void> requestCrawlConfig(int configId) async {}

  @override
  Future<void> requestMatchAnalysis(int jobId, {required int resumeId}) async {}

  @override
  Future<void> deleteResume(int resumeId) async {}

  @override
  Future<void> selectResumeForMatch(int resumeId) async {}

  @override
  Future<void> createProfile({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  }) async {}

  @override
  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  }) async {}

  @override
  Future<void> copyProfile(String profileKey) async {}

  @override
  Future<void> deleteProfile(String profileKey) async {}

  @override
  Future<void> releaseStaleProfile(String profileKey) async {}

  @override
  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> closeProfileLoginSession(String profileKey) async {}

  @override
  Future<void> testProfile({
    required String profileKey,
    required String platform,
  }) async {}
}

class _FakeFileService extends FileService {
  _FakeFileService()
    : super(canPickFiles: true, canSaveFiles: true, canDownloadFiles: true);

  int _pickCount = 0;
  String? savedName;

  @override
  Future<PickedFileReference?> pickFile() async {
    _pickCount += 1;
    if (_pickCount == 1) {
      return const PickedFileReference(name: 'resume-new.pdf', bytes: [1]);
    }
    return const PickedFileReference(name: 'profiles.zip', bytes: [2]);
  }

  @override
  Future<void> saveBytes({
    required String suggestedName,
    required List<int> bytes,
  }) async {
    savedName = suggestedName;
  }
}
