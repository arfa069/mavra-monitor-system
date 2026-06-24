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
    this.motionSpeed = 'normal',
  });

  final int dataRetentionDays;
  final String? feishuWebhookUrl;
  final String themeMode;
  final String motionSpeed;
}

class SettingsSnapshot {
  const SettingsSnapshot({
    required this.userConfig,
    required this.themeMode,
    this.motionSpeed = 'normal',
  });

  const SettingsSnapshot.empty()
    : userConfig = null,
      themeMode = 'system',
      motionSpeed = 'normal';

  final UserSettingsConfig? userConfig;
  final String themeMode;
  final String motionSpeed;

  bool get isEmpty => userConfig == null;
}

abstract class SettingsRepository {
  Future<SettingsSnapshot> loadSettings();

  Future<SettingsSnapshot> saveSettings(SettingsDraft draft);

  Future<SettingsSnapshot> saveMotionSpeed(String motionSpeed);
}
