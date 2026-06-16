import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/files/file_service.dart';
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
      expect(find.text('Run crawl'), findsNothing);
      expect(find.text('Run match'), findsNothing);
    },
  );

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

  @override
  Future<JobsSnapshot> loadJobs() async => snapshot;

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
  Future<void> importProfileBackup(PickedFileReference file) async {
    importedBackupName = file.name;
  }

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    exportedProfileKey = profileKey;
    return ProfileBackupExport(fileName: '$profileKey.zip', bytes: const [9]);
  }
}

class _SlowJobsRepository implements JobsRepository {
  final _completer = Completer<JobsSnapshot>();

  @override
  Future<JobsSnapshot> loadJobs() => _completer.future;

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {}

  @override
  Future<void> uploadResume(PickedFileReference file) async {}

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {}

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    return const ProfileBackupExport(fileName: 'backup.zip', bytes: []);
  }
}

class _FailingJobsRepository implements JobsRepository {
  @override
  Future<JobsSnapshot> loadJobs() {
    throw StateError('jobs down');
  }

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {}

  @override
  Future<void> uploadResume(PickedFileReference file) async {}

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {}

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    return const ProfileBackupExport(fileName: 'backup.zip', bytes: []);
  }
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
