import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../domain/settings_models.dart';

class GeneratedSettingsRepository implements SettingsRepository {
  GeneratedSettingsRepository({
    required AppConfig config,
    generated.MavraApi? client,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           );

  final generated.MavraApi _client;

  generated.ConfigApi get _configApi => _client.getConfigApi();

  @override
  Future<SettingsSnapshot> loadSettings() async {
    final response = await _configApi.configGetConfig();
    final config = response.data;
    if (config == null) {
      return const SettingsSnapshot.empty();
    }
    return SettingsSnapshot(
      userConfig: _mapConfig(config),
      themeMode: 'system',
      motionSpeed: 'normal',
    );
  }

  @override
  Future<SettingsSnapshot> saveSettings(SettingsDraft draft) async {
    final response = await _configApi.configUpdateConfigPartial(
      userConfigUpdate: generated.UserConfigUpdate(
        (builder) => builder
          ..dataRetentionDays = draft.dataRetentionDays
          ..feishuWebhookUrl = draft.feishuWebhookUrl ?? '',
      ),
    );
    final config = response.data;
    if (config == null) {
      return const SettingsSnapshot.empty();
    }
    return SettingsSnapshot(
      userConfig: _mapConfig(config),
      themeMode: draft.themeMode,
      motionSpeed: draft.motionSpeed,
    );
  }

  @override
  Future<SettingsSnapshot> saveMotionSpeed(String motionSpeed) async {
    final current = await loadSettings();
    return SettingsSnapshot(
      userConfig: current.userConfig,
      themeMode: current.themeMode,
      motionSpeed: motionSpeed,
    );
  }

  static UserSettingsConfig _mapConfig(generated.UserConfigResponse config) {
    return UserSettingsConfig(
      id: config.id,
      username: config.username,
      dataRetentionDays: config.dataRetentionDays ?? 365,
      feishuWebhookUrl: config.feishuWebhookUrl,
      updatedAt: config.updatedAt,
    );
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
