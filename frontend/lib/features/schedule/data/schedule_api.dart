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
      _productsApi.productsGetProductCronSchedules(),
      _jobsApi.jobsGetJobConfigSchedules(),
      _schedulerApi.schedulerGetSchedulerStatus(),
      _configApi.configGetConfig(),
    ]);

    final productData =
        responses[0].data as generated.ProductCronSchedulesResponse?;
    final jobData = responses[1].data as generated.JobConfigSchedulesResponse?;
    final statusData = responses[2].data as generated.SchedulerStatusResponse?;
    final configData = responses[3].data as generated.UserConfigResponse?;
    final productEntries =
        productData?.platforms?.entries.toList() ??
        const <MapEntry<String, generated.ScheduleInfo>>[];

    return ScheduleSnapshot(
      status: SchedulerStatus(
        label: _schedulerLabel(statusData?.scheduler),
        timezone: statusData?.timezone,
      ),
      productSchedules: [
        for (final entry in productEntries)
          ProductSchedule(
            platform: entry.key,
            cronExpression: entry.value.cronExpression ?? 'Disabled',
            nextRunAt: entry.value.nextRunAt,
          ),
      ],
      jobSchedules: [
        for (final config in jobData?.configs?.toList() ?? const [])
          JobSchedule(
            configId: config.configId,
            name: 'Job config #${config.configId}',
            cronExpression: config.cronExpression ?? 'Disabled',
            nextRunAt: config.nextRunAt,
          ),
      ],
      settings: ScheduleSettings(
        retentionDays: configData?.dataRetentionDays ?? 365,
        feishuWebhookUrl: configData?.feishuWebhookUrl,
      ),
      canConfigure: true,
    );
  }

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    CronGenerator.validateDraft(draft);
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {
    CronGenerator.validateDraft(draft);
    switch (draft.targetType) {
      case ScheduleRuleTarget.productPlatform:
        await _productsApi.productsCreateProductCronConfig(
          productPlatformCronCreate: generated.ProductPlatformCronCreate(
            (builder) => builder
              ..platform = draft.targetName
              ..cronExpression = draft.cronExpression
              ..cronTimezone = draft.timezone,
          ),
        );
      case ScheduleRuleTarget.jobConfig:
        await _jobsApi.jobsUpdateConfigCron(
          configId: draft.configId!,
          jobConfigCronUpdate: generated.JobConfigCronUpdate(
            (builder) => builder
              ..cronExpression = draft.cronExpression
              ..cronTimezone = draft.timezone,
          ),
        );
    }
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

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
