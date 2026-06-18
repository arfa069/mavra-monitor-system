import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../domain/smart_home_models.dart';

class GeneratedSmartHomeRepository implements SmartHomeRepository {
  GeneratedSmartHomeRepository({
    required AppConfig config,
    generated.MavraApi? client,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           );

  final generated.MavraApi _client;

  generated.SmartHomeApi get _smartHomeApi => _client.getSmartHomeApi();

  @override
  Future<SmartHomeSnapshot> loadSmartHome() async {
    final responses = await Future.wait([
      _smartHomeApi.smartHomeGetConfig(),
      _smartHomeApi.smartHomeGetSummary(),
      _smartHomeApi.smartHomeListEntities(),
    ]);

    final config = responses[0].data as generated.SmartHomeConfigResponse?;
    final summary = responses[1].data as generated.SmartHomeSummaryResponse?;
    final entities =
        responses[2].data as generated.SmartHomeEntityListResponse?;

    return SmartHomeSnapshot(
      config: config == null
          ? null
          : SmartHomeConfig(
              baseUrl: config.baseUrl,
              enabled: config.enabled,
              lastStatus: config.lastStatus,
              tokenConfigured: config.tokenConfigured ?? false,
            ),
      summary: SmartHomeSummary(
        configured: summary?.configured ?? false,
        connected: summary?.connected ?? entities?.connected ?? false,
        activeCount: summary?.activeCount ?? 0,
        unavailableCount:
            summary?.unavailableCount ??
            (entities?.items
                    .where((entity) => entity.available == false)
                    .length ??
                0),
      ),
      entities: [
        for (final entity in entities?.items.toList() ?? const [])
          SmartHomeEntityItem(
            domain: _domainName(entity.domain),
            entityId: entity.entityId,
            name: entity.name,
            state: entity.state,
            area: entity.area,
            available: entity.available ?? true,
          ),
      ],
      canControl: true,
      canConfigure: true,
      realtimeConnected: entities?.connected ?? summary?.connected ?? false,
    );
  }

  @override
  Stream<List<SmartHomeEntityItem>> watchEntities() {
    return const Stream.empty();
  }

  @override
  Future<void> saveConfig(SmartHomeConfigDraft draft) async {
    final token = draft.token?.trim();
    await _smartHomeApi.smartHomeUpdateConfig(
      smartHomeConfigUpdate: generated.SmartHomeConfigUpdate(
        (builder) => builder
          ..baseUrl = draft.baseUrl
          ..enabled = draft.enabled
          ..token = token == null || token.isEmpty ? null : token,
      ),
    );
  }

  @override
  Future<SmartHomeServiceResult> testConfig(SmartHomeConfigDraft draft) async {
    final token = draft.token?.trim();
    final response = await _smartHomeApi.smartHomeTestConfig(
      smartHomeConfigTestRequest: generated.SmartHomeConfigTestRequest(
        (builder) => builder
          ..baseUrl = draft.baseUrl
          ..token = token == null || token.isEmpty ? null : token,
      ),
    );
    final data = response.data;
    final version = data?.homeAssistantVersion;
    final message = version == null || version.isEmpty
        ? data?.message
        : '${data?.message} ($version)';
    return SmartHomeServiceResult(
      ok: data?.ok ?? false,
      message: message ?? 'Config test completed',
    );
  }

  @override
  Future<SmartHomeServiceResult> callService(
    SmartHomeServiceDraft draft,
  ) async {
    final response = await _smartHomeApi.smartHomeCallService(
      smartHomeServiceRequest: generated.SmartHomeServiceRequest(
        (builder) => builder
          ..entityId = draft.entityId
          ..service = draft.service,
      ),
    );
    final data = response.data;
    return SmartHomeServiceResult(
      ok: data?.ok ?? false,
      message: data?.message ?? 'Service call queued',
    );
  }

  static String _domainName(Object value) {
    final raw = value.toString().split('.').last;
    return raw.endsWith('_') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
