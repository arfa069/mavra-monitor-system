class SchedulerStatus {
  const SchedulerStatus({required this.label, required this.timezone});

  final String label;
  final String? timezone;
}

class ProductSchedule {
  const ProductSchedule({
    required this.platform,
    required this.cronExpression,
    required this.nextRunAt,
    this.timezone = 'Asia/Shanghai',
    this.configured = true,
  });

  final String platform;
  final String cronExpression;
  final String? nextRunAt;
  final String timezone;
  final bool configured;
}

class JobSchedule {
  const JobSchedule({
    required this.configId,
    required this.name,
    required this.cronExpression,
    required this.nextRunAt,
    this.timezone = 'Asia/Shanghai',
    this.configured = true,
  });

  final int configId;
  final String name;
  final String cronExpression;
  final String? nextRunAt;
  final String timezone;
  final bool configured;
}

class ScheduleSettings {
  const ScheduleSettings({required this.retentionDays, this.feishuWebhookUrl});

  static const defaults = ScheduleSettings(retentionDays: 365);

  final int retentionDays;
  final String? feishuWebhookUrl;
}

class ScheduleSnapshot {
  const ScheduleSnapshot({
    required this.status,
    required this.productSchedules,
    required this.jobSchedules,
    required this.settings,
    required this.canConfigure,
  });

  const ScheduleSnapshot.empty()
    : status = const SchedulerStatus(
        label: 'Scheduler stopped',
        timezone: null,
      ),
      productSchedules = const [],
      jobSchedules = const [],
      settings = ScheduleSettings.defaults,
      canConfigure = true;

  final SchedulerStatus status;
  final List<ProductSchedule> productSchedules;
  final List<JobSchedule> jobSchedules;
  final ScheduleSettings settings;
  final bool canConfigure;

  bool get hasRules => productSchedules.isNotEmpty || jobSchedules.isNotEmpty;
}

enum ScheduleRuleTarget { productPlatform, jobConfig }

class ScheduleRuleDraft {
  const ScheduleRuleDraft({
    required this.targetType,
    required this.targetName,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.configId,
    this.timezone = 'Asia/Shanghai',
  });

  final ScheduleRuleTarget targetType;
  final String targetName;
  final int hour;
  final int minute;
  final String weekdays;
  final int? configId;
  final String timezone;

  String get cronExpression => CronGenerator.expressionFor(
    hour: hour,
    minute: minute,
    weekdays: weekdays,
  );
}

class CronPreview {
  const CronPreview({required this.expression});

  final String expression;
}

abstract class ScheduleRepository {
  Future<ScheduleSnapshot> loadSchedule();

  Future<List<ProductSchedule>> listProductSchedules();

  Future<List<JobSchedule>> listJobSchedules();

  Future<CronPreview> previewCron(ScheduleRuleDraft draft);

  Future<CronPreview> generateCron(ScheduleRuleDraft draft);

  Future<void> saveRule(ScheduleRuleDraft draft);

  Future<void> saveProductCron({
    required String platform,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  });

  Future<void> createProductCron({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  });

  Future<void> deleteProductCron(String platform);

  Future<void> saveJobCron({
    required int configId,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  });

  Future<void> saveSettings(ScheduleSettings settings);
}

class ScheduleValidationException implements Exception {
  const ScheduleValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CronGenerator {
  const CronGenerator._();

  static const presets = [
    CronPreset(label: 'Every hour', expression: '0 * * * *'),
    CronPreset(label: 'Daily at 9am', expression: '0 9 * * *'),
    CronPreset(label: 'Weekdays at 6pm', expression: '0 18 * * 1-5'),
    CronPreset(label: 'Every Monday', expression: '0 9 * * 1'),
    CronPreset(label: 'Every 30 min', expression: '*/30 * * * *'),
  ];

  static String expressionFor({
    required int hour,
    required int minute,
    required String weekdays,
  }) {
    _validateHour(hour);
    _validateMinute(minute);
    final normalizedWeekdays = _normalizeWeekdays(weekdays);
    return '$minute $hour * * $normalizedWeekdays';
  }

  static bool isValidExpression(String? expression) {
    final trimmed = expression?.trim() ?? '';
    if (trimmed.isEmpty) {
      return true;
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length != 5) {
      return false;
    }
    return parts.every(_isValidCronPart);
  }

  static String? fromNaturalLanguage(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) {
      return null;
    }

    final normalized = text
        .replaceAll('：', ':')
        .replaceAll('點', '点')
        .replaceAll('週', '周')
        .replaceAll('星期', '周');

    for (final preset in presets) {
      if (normalized == preset.label.toLowerCase()) {
        return preset.expression;
      }
    }

    final everyMinutes = RegExp(
      r'(?:every|每)\s*(\d+)\s*(?:minutes?|mins?|分钟|分)',
    ).firstMatch(normalized);
    if (everyMinutes != null) {
      final minutes = int.tryParse(everyMinutes.group(1)!);
      if (minutes != null && minutes > 0 && minutes <= 59) {
        return '*/$minutes * * * *';
      }
    }

    final hourMinute = _parseTime(normalized);
    if (hourMinute == null) {
      return null;
    }
    final minute = hourMinute.$2;
    final hour = hourMinute.$1;

    if (_containsAny(normalized, const ['weekday', 'workday', '周一到周五'])) {
      return '$minute $hour * * 1-5';
    }
    if (_containsAny(normalized, const ['daily', 'every day', '每天', '每日'])) {
      return '$minute $hour * * *';
    }

    final dayOfWeek = _parseDayOfWeek(normalized);
    if (dayOfWeek != null) {
      return '$minute $hour * * $dayOfWeek';
    }

    return '$minute $hour * * *';
  }

  static void validateDraft(ScheduleRuleDraft draft) {
    if (draft.targetName.trim().isEmpty) {
      throw const ScheduleValidationException('Target is required');
    }
    if (draft.targetType == ScheduleRuleTarget.jobConfig &&
        draft.configId == null) {
      throw const ScheduleValidationException('Job config id is required');
    }
    expressionFor(
      hour: draft.hour,
      minute: draft.minute,
      weekdays: draft.weekdays,
    );
  }

  static void _validateHour(int hour) {
    if (hour < 0 || hour > 23) {
      throw const ScheduleValidationException('Hour must be 0-23');
    }
  }

  static void _validateMinute(int minute) {
    if (minute < 0 || minute > 59) {
      throw const ScheduleValidationException('Minute must be 0-59');
    }
  }

  static String _normalizeWeekdays(String weekdays) {
    final trimmed = weekdays.trim();
    if (trimmed.isEmpty) {
      return '*';
    }
    final valid = RegExp(r'^(\*|[0-7](?:-[0-7])?(?:,[0-7](?:-[0-7])?)*)$');
    if (!valid.hasMatch(trimmed)) {
      throw const ScheduleValidationException(
        'Weekdays must be *, 1-5, or a comma list',
      );
    }
    return trimmed;
  }

  static bool _isValidCronPart(String part) {
    return RegExp(r'^(\*|\*/\d+|\d+|\d+-\d+|\d+(,\d+)+)$').hasMatch(part);
  }

  static (int, int)? _parseTime(String text) {
    final colonTime = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?').firstMatch(text);
    if (colonTime != null) {
      final hour = _normalizeHour(
        int.parse(colonTime.group(1)!),
        colonTime.group(3),
      );
      final minute = int.parse(colonTime.group(2)!);
      if (_isValidTime(hour, minute)) {
        return (hour, minute);
      }
    }

    final englishHour = RegExp(
      r'(?:at\s*)?(\d{1,2})\s*(am|pm)',
    ).firstMatch(text);
    if (englishHour != null) {
      final hour = _normalizeHour(
        int.parse(englishHour.group(1)!),
        englishHour.group(2),
      );
      if (_isValidTime(hour, 0)) {
        return (hour, 0);
      }
    }

    final chineseHour = RegExp(
      r'(?:早上|上午|中午|下午|晚上|晚)?\s*(\d{1,2})\s*点(?:半|(\d{1,2})分?)?',
    ).firstMatch(text);
    if (chineseHour != null) {
      var hour = int.parse(chineseHour.group(1)!);
      var minute = chineseHour.group(0)!.contains('半')
          ? 30
          : int.tryParse(chineseHour.group(2) ?? '') ?? 0;
      if (_containsAny(text, const ['下午', '晚上', '晚']) && hour < 12) {
        hour += 12;
      }
      if (text.contains('中午') && hour < 11) {
        hour += 12;
      }
      if (_isValidTime(hour, minute)) {
        return (hour, minute);
      }
    }

    return null;
  }

  static int _normalizeHour(int hour, String? meridiem) {
    if (meridiem == null) {
      return hour;
    }
    if (meridiem == 'pm' && hour < 12) {
      return hour + 12;
    }
    if (meridiem == 'am' && hour == 12) {
      return 0;
    }
    return hour;
  }

  static bool _isValidTime(int hour, int minute) {
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  static int? _parseDayOfWeek(String text) {
    const englishDays = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 0,
    };
    for (final entry in englishDays.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    const chineseDays = {
      '周一': 1,
      '周二': 2,
      '周三': 3,
      '周四': 4,
      '周五': 5,
      '周六': 6,
      '周日': 0,
      '周天': 0,
    };
    for (final entry in chineseDays.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static bool _containsAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }
}

class CronPreset {
  const CronPreset({required this.label, required this.expression});

  final String label;
  final String expression;
}
