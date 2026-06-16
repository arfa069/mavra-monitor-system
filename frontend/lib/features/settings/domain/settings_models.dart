class UserSettingsConfig {
  const UserSettingsConfig({
    required this.id,
    required this.username,
    required this.dataRetentionDays,
    required this.feishuWebhookUrl,
    required this.updatedAt,
  });

  final int id;
  final String username;
  final int dataRetentionDays;
  final String? feishuWebhookUrl;
  final DateTime? updatedAt;
}

class SettingsDraft {
  const SettingsDraft({
    required this.dataRetentionDays,
    required this.feishuWebhookUrl,
    required this.themeMode,
  });

  final int dataRetentionDays;
  final String? feishuWebhookUrl;
  final String themeMode;
}

class SettingsSnapshot {
  const SettingsSnapshot({required this.userConfig, required this.themeMode});

  const SettingsSnapshot.empty() : userConfig = null, themeMode = 'system';

  final UserSettingsConfig? userConfig;
  final String themeMode;

  bool get isEmpty => userConfig == null;
}

abstract class SettingsRepository {
  Future<SettingsSnapshot> loadSettings();

  Future<SettingsSnapshot> saveSettings(SettingsDraft draft);
}
