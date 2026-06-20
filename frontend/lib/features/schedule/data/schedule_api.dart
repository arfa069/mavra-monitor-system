import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../domain/schedule_models.dart';

class GeneratedScheduleRepository implements ScheduleRepository {
  GeneratedScheduleRepository({
    required AppConfig config,
    generated.MavraApi? client,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           );

  final generated.MavraApi _client;

  generated.ProductsApi get _productsApi => _client.getProductsApi();

  generated.JobsApi get _jobsApi => _client.getJobsApi();

  generated.SchedulerApi get _schedulerApi => _client.getSchedulerApi();

  generated.ConfigApi get _configApi => _client.getConfigApi();

  @override
  Future<ScheduleSnapshot> loadSchedule() async {
    final responses = await Future.wait([
      _productsApi.productsListProductCronConfigs(),
      _productsApi.productsGetProductCronSchedules(),
      _jobsApi.jobsListConfigs(),
      _jobsApi.jobsGetJobConfigSchedules(),
      _schedulerApi.schedulerGetSchedulerStatus(),
      _configApi.configGetConfig(),
    ]);

    final productData =
        responses[0].data as Iterable<generated.ProductPlatformCronResponse>?;
    final productScheduleData =
        responses[1].data as generated.ProductCronSchedulesResponse?;
    final jobConfigData =
        responses[2].data as Iterable<generated.JobSearchConfigResponse>?;
    final jobScheduleData =
        responses[3].data as generated.JobConfigSchedulesResponse?;
    final statusData = responses[4].data as generated.SchedulerStatusResponse?;
    final configData = responses[5].data as generated.UserConfigResponse?;
    final jobSchedulesByConfigId = {
      for (final schedule in jobScheduleData?.configs?.toList() ?? const [])
        schedule.configId: schedule,
    };

    return ScheduleSnapshot(
      status: SchedulerStatus(
        label: _schedulerLabel(statusData?.scheduler),
        timezone: statusData?.timezone,
      ),
      productSchedules: [
        for (final config in productData?.toList() ?? const [])
          ProductSchedule(
            platform: config.platform,
            cronExpression: config.cronExpression ?? '',
            nextRunAt:
                productScheduleData?.platforms?[config.platform]?.nextRunAt,
            timezone: config.cronTimezone,
            configured: _isConfigured(config.cronExpression),
          ),
      ],
      jobSchedules: [
        for (final config in jobConfigData?.toList() ?? const [])
          JobSchedule(
            configId: config.id,
            name: config.name,
            cronExpression: config.cronExpression ?? '',
            nextRunAt: jobSchedulesByConfigId[config.id]?.nextRunAt,
            timezone: config.cronTimezone ?? 'Asia/Shanghai',
            configured: _isConfigured(config.cronExpression),
          ),
      ],
      settings: ScheduleSettings(
        retentionDays: configData?.dataRetentionDays ?? 365,
        feishuWebhookUrl: configData?.feishuWebhookUrl,
      ),
      canConfigure: false,
    );
  }

  @override
  Future<List<ProductSchedule>> listProductSchedules() async {
    return (await loadSchedule()).productSchedules;
  }

  @override
  Future<List<JobSchedule>> listJobSchedules() async {
    return (await loadSchedule()).jobSchedules;
  }

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    CronGenerator.validateDraft(draft);
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<CronPreview> generateCron(ScheduleRuleDraft draft) {
    return previewCron(draft);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {
    CronGenerator.validateDraft(draft);
    switch (draft.targetType) {
      case ScheduleRuleTarget.productPlatform:
        await createProductCron(
          platform: draft.targetName,
          cronExpression: draft.cronExpression,
          timezone: draft.timezone,
        );
      case ScheduleRuleTarget.jobConfig:
        await saveJobCron(
          configId: draft.configId!,
          cronExpression: draft.cronExpression,
          timezone: draft.timezone,
        );
    }
  }

  @override
  Future<void> saveProductCron({
    required String platform,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {
    final normalizedCron = cronExpression?.trim() ?? '';
    if (normalizedCron.isEmpty) {
      await deleteProductCron(platform);
      return;
    }
    await _productsApi.productsUpdateProductCronConfig(
      platform: platform,
      productPlatformCronUpdate: generated.ProductPlatformCronUpdate(
        (builder) => builder
          ..cronExpression = normalizedCron
          ..cronTimezone = timezone,
      ),
    );
  }

  @override
  Future<void> createProductCron({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {
    await _productsApi.productsCreateProductCronConfig(
      productPlatformCronCreate: generated.ProductPlatformCronCreate(
        (builder) => builder
          ..platform = platform
          ..cronExpression = cronExpression.trim()
          ..cronTimezone = timezone,
      ),
    );
  }

  @override
  Future<void> deleteProductCron(String platform) async {
    await _productsApi.productsDeleteProductCronConfig(platform: platform);
  }

  @override
  Future<void> saveJobCron({
    required int configId,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {
    final normalizedCron = cronExpression?.trim();
    if (normalizedCron == null || normalizedCron.isEmpty) {
      await _client.dio.patch<Object>(
        '/api/v1/jobs/configs/$configId/cron',
        data: {'cron_expression': null, 'cron_timezone': timezone},
      );
      return;
    }
    await _jobsApi.jobsUpdateConfigCron(
      configId: configId,
      jobConfigCronUpdate: generated.JobConfigCronUpdate(
        (builder) => builder
          ..cronExpression = normalizedCron
          ..cronTimezone = timezone,
      ),
    );
  }

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {
    await _configApi.configUpdateConfigPartial(
      userConfigUpdate: generated.UserConfigUpdate(
        (builder) => builder
          ..dataRetentionDays = settings.retentionDays
          ..feishuWebhookUrl = settings.feishuWebhookUrl,
      ),
    );
  }

  static String _schedulerLabel(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return 'Scheduler unknown';
    }
    return 'Scheduler $normalized';
  }

  static bool _isConfigured(String? cronExpression) {
    return cronExpression?.trim().isNotEmpty ?? false;
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
