import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/notifications/mavra_notifier.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';
import 'package:mavra_frontend/features/schedule/domain/schedule_models.dart';
import 'package:mavra_frontend/features/schedule/presentation/schedule_page.dart';
import 'package:mavra_frontend/visual_qa/visual_qa_app.dart';

void main() {
  testWidgets('renders product timers as the default schedule tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SchedulePage(repository: _FakeScheduleRepository.full()),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Schedule Configuration'), findsOneWidget);
    expect(find.text('Scheduler running'), findsOneWidget);
    expect(find.text('Asia/Shanghai'), findsOneWidget);
    expect(
      find.byKey(const Key('schedule-tab-product-timers')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('schedule-tab-job-timers')), findsOneWidget);
    expect(find.byKey(const Key('schedule-tab-settings')), findsOneWidget);
    _expectSelectedTabContrast(
      tester,
      const Key('schedule-tab-product-timers'),
    );
    expect(find.text('Product Timers'), findsWidgets);
    expect(find.text('Job Timers'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    expect(find.byKey(const Key('schedule-product-table')), findsOneWidget);
    expect(
      find.byType(MavraResponsiveDataView<ProductSchedule>),
      findsOneWidget,
    );
    expect(find.byKey(const Key('schedule-job-table')), findsNothing);
    expect(find.text('Data Retention & Notification Config'), findsNothing);
    expect(find.text('Product Crawl Schedule Config'), findsOneWidget);
    expect(find.text('Job Crawl Schedule Config'), findsNothing);
    expect(find.text('taobao'), findsOneWidget);
    expect(
      find.byKey(const Key('schedule-product-cron-taobao-field')),
      findsOneWidget,
    );
    expect(find.textContaining('2026-06-17 09:00'), findsOneWidget);
  });

  testWidgets('keeps the product timers panel title horizontal on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/schedule'));
    await tester.pumpAndSettle();

    final titleBox = tester.renderObject<RenderBox>(
      find.text('Product Crawl Schedule Config'),
    );
    expect(titleBox.size.width, greaterThan(220));
    expect(titleBox.size.height, lessThan(48));
  });

  testWidgets('switches between job timers and settings tabs', (tester) async {
    await tester.pumpWidget(
      _host(SchedulePage(repository: _FakeScheduleRepository.full())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('schedule-tab-job-timers')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('schedule-product-table')), findsNothing);
    expect(find.byKey(const Key('schedule-job-table')), findsOneWidget);
    expect(find.text('Job Crawl Schedule Config'), findsOneWidget);
    expect(find.text('Product Crawl Schedule Config'), findsNothing);
    expect(find.text('Boss morning'), findsOneWidget);
    expect(find.byKey(const Key('schedule-job-cron-7-field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('schedule-tab-settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('schedule-product-table')), findsNothing);
    expect(find.byKey(const Key('schedule-job-table')), findsNothing);
    expect(find.text('Data Retention & Notification Config'), findsOneWidget);
    expect(
      find.byKey(const Key('schedule-retention-days-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('schedule-webhook-url-field')), findsOneWidget);
  });

  testWidgets('updates, creates, and deletes product cron timers', (
    tester,
  ) async {
    final repository = _FakeScheduleRepository.full();
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(SchedulePage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('schedule-product-cron-taobao-field')),
      '15 10 * * 1-5',
    );
    await tester.tap(
      find.byKey(const Key('schedule-product-save-taobao-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.savedProductPlatform, 'taobao');
    expect(repository.savedProductCronExpression, '15 10 * * 1-5');
    expect(find.text('Saved taobao schedule'), findsOneWidget);

    await tester.tap(find.byKey(const Key('schedule-add-product-button')));
    await tester.pumpAndSettle();
    expect(find.text('Add Product Crawl Timer'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('schedule-add-product-platform-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('JD').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-add-product-cron-field')),
      '0 11 * * *',
    );
    await tester.tap(
      find.byKey(const Key('schedule-add-product-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.createdProductPlatform, 'jd');
    expect(repository.createdProductCronExpression, '0 11 * * *');

    await tester.tap(
      find.byKey(const Key('schedule-product-delete-taobao-button')),
    );
    await tester.pumpAndSettle();
    expect(repository.deletedProductCronPlatform, 'taobao');
  });

  testWidgets('updates and disables job cron timers', (tester) async {
    final repository = _FakeScheduleRepository.full();
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(SchedulePage(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-tab-job-timers')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('schedule-job-cron-7-field')),
      '45 7 * * 1-5',
    );
    await tester.tap(find.byKey(const Key('schedule-job-save-7-button')));
    await tester.pumpAndSettle();

    expect(repository.savedJobCronConfigId, 7);
    expect(repository.savedJobCronExpression, '45 7 * * 1-5');
    expect(find.text('Saved Boss morning schedule'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('schedule-job-cron-7-field')),
      '',
    );
    await tester.tap(find.byKey(const Key('schedule-job-save-7-button')));
    await tester.pumpAndSettle();

    expect(repository.disabledJobCronConfigId, 7);
    expect(repository.savedJobCronExpression, isNull);
  });

  testWidgets('applies cron generator presets and natural-language output', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(SchedulePage(repository: _FakeScheduleRepository.full())),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('schedule-product-generate-taobao-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cron Expression Generator'), findsOneWidget);
    await tester.tap(find.text('Weekdays at 6pm'));
    await tester.pumpAndSettle();
    expect(find.text('0 18 * * 1-5'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('schedule-cron-generator-apply-button')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('schedule-product-cron-taobao-field')),
          )
          .controller
          ?.text,
      '0 18 * * 1-5',
    );

    await tester.tap(find.byKey(const Key('schedule-tab-job-timers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-job-generate-7-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-cron-generator-input')),
      '每天早上9点',
    );
    await tester.tap(
      find.byKey(const Key('schedule-cron-generator-generate-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 9 * * *'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('schedule-cron-generator-apply-button')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('schedule-job-cron-7-field')))
          .controller
          ?.text,
      '0 9 * * *',
    );
  });

  testWidgets('saves retention and webhook configuration from settings tab', (
    tester,
  ) async {
    final repository = _FakeScheduleRepository.full();

    await tester.pumpWidget(_host(SchedulePage(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-tab-settings')));
    await tester.pumpAndSettle();

    expect(find.text('Data Retention & Notification Config'), findsOneWidget);
    expect(find.text('365 days'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('schedule-retention-days-field')),
      '180',
    );
    await tester.enterText(
      find.byKey(const Key('schedule-webhook-url-field')),
      'https://open.feishu.cn/webhook/test',
    );
    await tester.tap(find.byKey(const Key('schedule-save-settings-button')));
    await tester.pumpAndSettle();

    expect(repository.savedSettings?.retentionDays, 180);
    expect(
      repository.savedSettings?.feishuWebhookUrl,
      'https://open.feishu.cn/webhook/test',
    );
    expect(find.text('Saved schedule settings'), findsOneWidget);
  });

  testWidgets('renders loading, empty, error, and read-only states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(SchedulePage(repository: _SlowScheduleRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在加载自动规则...'), findsOneWidget);

    await tester.pumpWidget(
      _host(SchedulePage(repository: _FakeScheduleRepository.empty())),
    );
    await tester.pumpAndSettle();
    expect(find.text('No product schedule configs'), findsOneWidget);

    await tester.pumpWidget(
      _host(SchedulePage(repository: _FailingScheduleRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('规则加载失败。'), findsOneWidget);

    await tester.pumpWidget(
      _host(SchedulePage(repository: _FakeScheduleRepository.readOnly())),
    );
    await tester.pumpAndSettle();
    expect(find.text('没有权限修改自动规则。'), findsOneWidget);
    final addProduct = tester.widget<FilledButton>(
      find.byKey(const Key('schedule-add-product-button')),
    );
    expect(addProduct.onPressed, isNull);
    final saveProduct = tester.widget<OutlinedButton>(
      find.byKey(const Key('schedule-product-save-taobao-button')),
    );
    expect(saveProduct.onPressed, isNull);
    final deleteProduct = tester.widget<IconButton>(
      find.byKey(const Key('schedule-product-delete-taobao-button')),
    );
    expect(deleteProduct.onPressed, isNull);
  });

  testWidgets('explicit permissions override repository canConfigure state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SchedulePage(
          repository: _FakeScheduleRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addProduct = tester.widget<FilledButton>(
      find.byKey(const Key('schedule-add-product-button')),
    );
    expect(addProduct.onPressed, isNull);

    await tester.tap(find.byKey(const Key('schedule-tab-settings')));
    await tester.pumpAndSettle();
    final saveSettings = tester.widget<FilledButton>(
      find.byKey(const Key('schedule-save-settings-button')),
    );
    expect(saveSettings.onPressed, isNull);
  });
}

Widget _host(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    scaffoldMessengerKey: MavraNotifier.scaffoldMessengerKey,
    home: child,
  );
}

void _expectSelectedTabContrast(WidgetTester tester, Key key) {
  final chip = tester.widget<ChoiceChip>(find.byKey(key));
  final icon = chip.avatar as Icon;

  expect(chip.labelStyle?.color, AppTheme.onPrimary);
  expect(icon.color, AppTheme.onPrimary);
}

class _FakeScheduleRepository implements ScheduleRepository {
  _FakeScheduleRepository(this.snapshot);

  factory _FakeScheduleRepository.full() => _FakeScheduleRepository(
    ScheduleSnapshot(
      status: const SchedulerStatus(
        label: 'Scheduler running',
        timezone: 'Asia/Shanghai',
      ),
      productSchedules: const [
        ProductSchedule(
          platform: 'taobao',
          cronExpression: '0 9 * * *',
          nextRunAt: '2026-06-17 09:00',
        ),
      ],
      jobSchedules: const [
        JobSchedule(
          configId: 7,
          name: 'Boss morning',
          cronExpression: '30 8 * * 1-5',
          nextRunAt: '2026-06-17 08:30',
        ),
      ],
      settings: const ScheduleSettings(
        retentionDays: 365,
        feishuWebhookUrl: 'https://open.feishu.cn/webhook/current',
      ),
      canConfigure: true,
    ),
  );

  factory _FakeScheduleRepository.empty() => _FakeScheduleRepository(
    const ScheduleSnapshot(
      status: SchedulerStatus(label: 'Scheduler stopped', timezone: null),
      productSchedules: [],
      jobSchedules: [],
      settings: ScheduleSettings.defaults,
      canConfigure: true,
    ),
  );

  factory _FakeScheduleRepository.readOnly() => _FakeScheduleRepository(
    ScheduleSnapshot(
      status: const SchedulerStatus(
        label: 'Scheduler running',
        timezone: 'Asia/Shanghai',
      ),
      productSchedules: const [
        ProductSchedule(
          platform: 'taobao',
          cronExpression: '0 9 * * *',
          nextRunAt: null,
        ),
      ],
      jobSchedules: const [
        JobSchedule(
          configId: 7,
          name: 'Boss morning',
          cronExpression: '30 8 * * 1-5',
          nextRunAt: null,
        ),
      ],
      settings: const ScheduleSettings(retentionDays: 365),
      canConfigure: false,
    ),
  );

  final ScheduleSnapshot snapshot;
  ScheduleSettings? savedSettings;
  String? savedProductPlatform;
  String? savedProductCronExpression;
  String? createdProductPlatform;
  String? createdProductCronExpression;
  String? deletedProductCronPlatform;
  int? savedJobCronConfigId;
  int? disabledJobCronConfigId;
  String? savedJobCronExpression;

  @override
  Future<ScheduleSnapshot> loadSchedule() async => snapshot;

  @override
  Future<List<ProductSchedule>> listProductSchedules() async {
    return snapshot.productSchedules;
  }

  @override
  Future<List<JobSchedule>> listJobSchedules() async {
    return snapshot.jobSchedules;
  }

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<CronPreview> generateCron(ScheduleRuleDraft draft) {
    return previewCron(draft);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {}

  @override
  Future<void> saveProductCron({
    required String platform,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {
    savedProductPlatform = platform;
    savedProductCronExpression = cronExpression;
  }

  @override
  Future<void> createProductCron({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {
    createdProductPlatform = platform;
    createdProductCronExpression = cronExpression;
  }

  @override
  Future<void> deleteProductCron(String platform) async {
    deletedProductCronPlatform = platform;
  }

  @override
  Future<void> saveJobCron({
    required int configId,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {
    savedJobCronConfigId = configId;
    savedJobCronExpression = cronExpression;
    if (cronExpression == null || cronExpression.isEmpty) {
      disabledJobCronConfigId = configId;
    }
  }

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {
    savedSettings = settings;
  }
}

class _SlowScheduleRepository implements ScheduleRepository {
  final _completer = Completer<ScheduleSnapshot>();

  @override
  Future<ScheduleSnapshot> loadSchedule() => _completer.future;

  @override
  Future<List<ProductSchedule>> listProductSchedules() async => const [];

  @override
  Future<List<JobSchedule>> listJobSchedules() async => const [];

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<CronPreview> generateCron(ScheduleRuleDraft draft) {
    return previewCron(draft);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {}

  @override
  Future<void> saveProductCron({
    required String platform,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> createProductCron({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> deleteProductCron(String platform) async {}

  @override
  Future<void> saveJobCron({
    required int configId,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {}
}

class _FailingScheduleRepository implements ScheduleRepository {
  @override
  Future<ScheduleSnapshot> loadSchedule() {
    throw StateError('scheduler down');
  }

  @override
  Future<List<ProductSchedule>> listProductSchedules() async => const [];

  @override
  Future<List<JobSchedule>> listJobSchedules() async => const [];

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<CronPreview> generateCron(ScheduleRuleDraft draft) {
    return previewCron(draft);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {}

  @override
  Future<void> saveProductCron({
    required String platform,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> createProductCron({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> deleteProductCron(String platform) async {}

  @override
  Future<void> saveJobCron({
    required int configId,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {}
}
